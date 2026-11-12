import Foundation
import Testing

@testable import TopwayCore

struct SampleDataSourceDatabaseTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    @Test("A sample database is a new service that runs in the selected environment")
    func deploy() async throws {
        let source = SampleDataSource(now: { [now] in now })

        let workflowId = try await source.deployDatabase(
            .mongo, projectId: "docs", environmentId: "docs-staging", token: "")

        #expect(workflowId == nil)
        #expect(source.waitForDatabase(workflowId: "none", token: "") == .complete)
        let docs = try #require(
            await source.fetchProjects(workspaceId: "", token: "").first { $0.id == "docs" })
        #expect(docs.serviceList.map(\.name) == ["site", "MongoDB"])
        let service = try #require(docs.serviceList.last)
        let deployments = await source.fetchDeployments(
            projectId: "docs", environmentId: "docs-staging", serviceId: service.id, token: "")
        #expect(deployments.map(\.status) == ["SUCCESS"])
        #expect(deployments.first?.createdAt == "2026-11-10T12:00:00Z")
        let variables = await source.fetchVariables(
            projectId: "docs", environmentId: "docs-staging", serviceId: service.id, token: "")
        #expect(
            variables["MONGO_URL"]
                == "mongodb://mongo:sample-password@mongodb.railway.internal:27017")
        let settings = try await source.fetchServiceSettings(
            environmentId: "docs-staging", serviceId: service.id, token: "")
        #expect(settings.source == "mongo:8.0")
        #expect(settings[.startCommand] == "")
    }

    @Test("A second database of the same kind gets a different name")
    func secondDatabase() async throws {
        let source = SampleDataSource()

        _ = try await source.deployDatabase(
            .redis, projectId: "docs", environmentId: "docs-production", token: "")
        _ = try await source.deployDatabase(
            .redis, projectId: "docs", environmentId: "docs-production", token: "")

        let docs = try #require(
            await source.fetchProjects(workspaceId: "", token: "").first { $0.id == "docs" })
        #expect(docs.serviceList.map(\.name) == ["site", "Redis", "Redis-2"])
    }

    @Test("A project or an environment that does not exist gives an error")
    func missingTarget() async {
        let source = SampleDataSource()

        await #expect(throws: RailwayError.self) {
            try await source.deployDatabase(
                .postgres, projectId: "missing", environmentId: "docs-production", token: "")
        }
        await #expect(throws: RailwayError.self) {
            try await source.deployDatabase(
                .postgres, projectId: "docs", environmentId: "storefront-production", token: "")
        }
    }
}
