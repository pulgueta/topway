import Foundation
import Testing

@testable import TopwayCore

struct SampleDataSourceEnvironmentTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    private func makeSource() -> SampleDataSource {
        SampleDataSource(now: { [now] in now })
    }

    private func docs(_ source: SampleDataSource) async throws -> Project {
        try #require(
            await source.fetchProjects(workspaceId: "", token: "").first { $0.id == "docs" })
    }

    @Test("Create adds an empty environment to the project")
    func createEmpty() async throws {
        let source = makeSource()

        let id = try await source.createEnvironment(
            projectId: "docs", name: "preview", sourceEnvironmentId: nil, token: "")

        let project = try await docs(source)
        #expect(project.environmentList.map(\.name) == ["production", "staging", "preview"])
        #expect(project.environmentList.last?.id == id)
        let deployments = await source.fetchDeployments(
            projectId: "docs", environmentId: id, serviceId: "docs-site", token: "")
        #expect(deployments.isEmpty)
    }

    @Test("Create from a source copies its variables and starts its services")
    func createFromSource() async throws {
        let source = makeSource()

        let id = try await source.createEnvironment(
            projectId: "docs", name: "preview", sourceEnvironmentId: "docs-production", token: "")

        let variables = await source.fetchVariables(
            projectId: "docs", environmentId: id, serviceId: "docs-site", token: "")
        #expect(variables == ["SITE_URL": "https://docs.example.com"])
        let deployments = await source.fetchDeployments(
            projectId: "docs", environmentId: id, serviceId: "docs-site", token: "")
        #expect(deployments.map(\.status) == ["SUCCESS"])
        #expect(deployments.first?.createdAt == "2026-11-10T12:00:00Z")
    }

    @Test("Create from a source does not copy a sealed variable, as on Railway")
    func createFromSourceWithSealedVariable() async throws {
        let source = makeSource()

        let id = try await source.createEnvironment(
            projectId: "storefront", name: "preview", sourceEnvironmentId: "storefront-production",
            token: "")

        let variables = await source.fetchVariables(
            projectId: "storefront", environmentId: id, serviceId: "storefront-api", token: "")
        #expect(variables["PORT"] == "8080")
        #expect(!variables.keys.contains("STRIPE_SECRET_KEY"))
    }

    @Test("Create fails with a message for a missing project and for a name in use")
    func createFailures() async {
        let source = makeSource()

        await #expect(throws: RailwayError.self) {
            try await source.createEnvironment(
                projectId: "missing", name: "preview", sourceEnvironmentId: nil, token: "")
        }
        await #expect(throws: RailwayError.self) {
            try await source.createEnvironment(
                projectId: "docs", name: "Staging", sourceEnvironmentId: nil, token: "")
        }
    }

    @Test("Delete removes the environment and its statuses")
    func delete() async throws {
        let source = makeSource()

        let didDelete = await source.deleteEnvironment(environmentId: "docs-production", token: "")

        #expect(didDelete)
        let project = try await docs(source)
        #expect(project.environmentList.map(\.name) == ["staging"])
        #expect(project.serviceStatuses.isEmpty)
        #expect(await !source.deleteEnvironment(environmentId: "docs-production", token: ""))
    }
}
