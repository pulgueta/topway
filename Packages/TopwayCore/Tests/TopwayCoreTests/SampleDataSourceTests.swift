import Foundation
import Testing

@testable import TopwayCore

struct SampleDataSourceTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    private func makeSource() -> SampleDataSource {
        SampleDataSource(now: { [now] in now })
    }

    @Test("Projects have services and a production and a staging environment")
    func projects() async throws {
        let projects = await makeSource().fetchProjects(workspaceId: "", token: "")

        let storefront = try #require(projects.first { $0.name == "storefront" })
        #expect(
            storefront.serviceList.map(\.name) == ["web", "api", "worker", "postgres", "redis"])
        #expect(storefront.environmentList.map(\.name) == ["production", "staging"])
        #expect(storefront.productionEnvironmentName == "production")
        #expect(projects.count == 3)
    }

    @Test("Deployments cover each status, and their dates come from now")
    func deployments() async throws {
        let source = makeSource()
        var statuses: Set<String> = []
        for project in await source.fetchProjects(workspaceId: "", token: "") {
            for environment in project.environmentList {
                for service in project.serviceList {
                    let deployments = await source.fetchDeployments(
                        projectId: project.id, environmentId: environment.id,
                        serviceId: service.id, token: "")
                    statuses.formUnion(deployments.map(\.status))
                }
            }
        }
        #expect(
            statuses == [
                "SUCCESS", "FAILED", "CRASHED", "BUILDING", "DEPLOYING", "QUEUED", "WAITING",
                "SKIPPED", "REMOVED", "SLEEPING",
            ])

        let web = await source.fetchDeployments(
            projectId: "storefront", environmentId: "storefront-production",
            serviceId: "storefront-web", token: "")
        #expect(web.first?.status == "SUCCESS")
        #expect(web.first?.createdAt == "2026-11-10T10:00:00Z")
    }

    @Test("Variables keep Railway references as plain values")
    func variables() async {
        let variables = await makeSource().fetchVariables(
            projectId: "storefront", environmentId: "storefront-production",
            serviceId: "storefront-api", token: "")

        #expect(
            variables == [
                "DATABASE_URL": "${{ postgres.DATABASE_URL }}",
                "REDIS_URL": "${{ redis.REDIS_URL }}",
                "LOG_LEVEL": "${{ shared.LOG_LEVEL }}",
                "PORT": "8080",
            ])
    }

    @Test("Restart makes a crashed deployment run again")
    func restart() async throws {
        let source = makeSource()
        let worker = await source.fetchDeployments(
            projectId: "storefront", environmentId: "storefront-production",
            serviceId: "storefront-worker", token: "")
        let crashed = try #require(worker.first { $0.status == "CRASHED" })

        let didRestart = await source.restartDeployment(deploymentId: crashed.id, token: "")

        #expect(didRestart)
        let after = await source.fetchDeployments(
            projectId: "storefront", environmentId: "storefront-production",
            serviceId: "storefront-worker", token: "")
        #expect(after.first { $0.id == crashed.id }?.status == "SUCCESS")
        #expect(await !source.restartDeployment(deploymentId: "missing", token: ""))
    }

    @Test("Redeploy adds a running deployment at now and removes the earlier one")
    func redeploy() async {
        let source = makeSource()
        let before = await source.fetchDeployments(
            projectId: "storefront", environmentId: "storefront-production",
            serviceId: "storefront-web", token: "")

        let didStart = await source.redeployService(
            environmentId: "storefront-production", serviceId: "storefront-web", token: "")

        #expect(didStart)
        let after = await source.fetchDeployments(
            projectId: "storefront", environmentId: "storefront-production",
            serviceId: "storefront-web", token: "")
        #expect(after.count == before.count + 1)
        #expect(after.first?.status == "SUCCESS")
        #expect(after.first?.createdAt == "2026-11-10T12:00:00Z")
        #expect(after.dropFirst().map(\.status) == ["REMOVED", "REMOVED", "FAILED"])
    }

    @Test("Upsert adds and changes a variable, and delete removes it")
    func upsertAndDeleteVariable() async {
        let source = makeSource()
        let ids = ("storefront", "storefront-staging", "storefront-api")

        let didAdd = await source.upsertVariable(
            projectId: ids.0, environmentId: ids.1, serviceId: ids.2, name: "FEATURE_FLAG",
            value: "on", token: "")
        let didChange = await source.upsertVariable(
            projectId: ids.0, environmentId: ids.1, serviceId: ids.2, name: "LOG_LEVEL",
            value: "info", token: "")
        let didDelete = await source.deleteVariable(
            projectId: ids.0, environmentId: ids.1, serviceId: ids.2, name: "PORT", token: "")

        #expect(didAdd && didChange && didDelete)
        let variables = await source.fetchVariables(
            projectId: ids.0, environmentId: ids.1, serviceId: ids.2, token: "")
        #expect(
            variables == [
                "DATABASE_URL": "${{ postgres.DATABASE_URL }}",
                "LOG_LEVEL": "info",
                "FEATURE_FLAG": "on",
            ])
        #expect(
            await !source.deleteVariable(
                projectId: ids.0, environmentId: ids.1, serviceId: ids.2, name: "PORT", token: ""))
    }

    @Test("Create adds a service with the name of the repository or the image")
    func createService() async throws {
        let source = makeSource()

        let repoId = try await source.createService(projectId: "docs", repo: "acme/blog", token: "")
        let imageId = try await source.createServiceWithImage(
            projectId: "docs", image: "ghcr.io/acme/search:1.2", token: "")

        let docs = try #require(
            await source.fetchProjects(workspaceId: "", token: "").first { $0.id == "docs" })
        #expect(docs.serviceList.map(\.name) == ["site", "blog", "search"])
        #expect(docs.serviceList.map(\.id).suffix(2) == [repoId, imageId])
        #expect(repoId != imageId)
        await #expect(throws: RailwayError.self) {
            try await source.createService(projectId: "missing", repo: "acme/blog", token: "")
        }
    }

    @Test("Delete removes a service and a project")
    func deleteServiceAndProject() async throws {
        let source = makeSource()

        let didDeleteService = await source.deleteService(serviceId: "storefront-redis", token: "")
        let didDeleteProject = await source.deleteProject(projectId: "analytics", token: "")

        #expect(didDeleteService && didDeleteProject)
        let projects = await source.fetchProjects(workspaceId: "", token: "")
        #expect(projects.map(\.name) == ["storefront", "docs"])
        let storefront = try #require(projects.first)
        #expect(storefront.serviceList.map(\.name) == ["web", "api", "worker", "postgres"])
        #expect(await !source.deleteService(serviceId: "storefront-redis", token: ""))
        #expect(await !source.deleteProject(projectId: "analytics", token: ""))
    }
}
