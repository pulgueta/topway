import Foundation
import Testing

@testable import TopwayCore

struct SampleDataSourceDeploymentActionTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    private func makeSource() -> SampleDataSource {
        SampleDataSource(now: { [now] in now })
    }

    @Test("The earlier deployment that ran can roll back, and the others cannot")
    func seedRollback() async {
        let web = await makeSource().fetchDeployments(
            projectId: "storefront", environmentId: "storefront-production",
            serviceId: "storefront-web", token: "")

        #expect(web.map(\.status) == ["SUCCESS", "REMOVED", "FAILED"])
        #expect(web.map(\.availableActions) == [[.remove], [.rollback], []])
    }

    @Test("Rollback starts a new deployment at now and removes the one that ran")
    func rollback() async throws {
        let source = makeSource()
        let ids = ("storefront", "storefront-production", "storefront-web")
        let before = await source.fetchDeployments(
            projectId: ids.0, environmentId: ids.1, serviceId: ids.2, token: "")
        let earlier = try #require(before.first { $0.status == "REMOVED" })

        let didStart = await source.rollbackDeployment(deploymentId: earlier.id, token: "")

        #expect(didStart)
        let after = await source.fetchDeployments(
            projectId: ids.0, environmentId: ids.1, serviceId: ids.2, token: "")
        #expect(after.map(\.status) == ["SUCCESS", "REMOVED", "REMOVED", "FAILED"])
        #expect(after.first?.createdAt == "2026-11-10T12:00:00Z")
        #expect(after[1].availableActions == [.rollback])
        #expect(await !source.rollbackDeployment(deploymentId: "missing", token: ""))
    }

    @Test("Cancel stops a build, and the stopped build cannot roll back")
    func cancel() async throws {
        let source = makeSource()
        let ids = ("storefront", "storefront-production", "storefront-api")
        let before = await source.fetchDeployments(
            projectId: ids.0, environmentId: ids.1, serviceId: ids.2, token: "")
        let building = try #require(before.first { $0.status == "BUILDING" })

        let didCancel = await source.cancelDeployment(deploymentId: building.id, token: "")

        #expect(didCancel)
        let after = await source.fetchDeployments(
            projectId: ids.0, environmentId: ids.1, serviceId: ids.2, token: "")
        #expect(after.map(\.status) == ["REMOVED", "SUCCESS", "REMOVED"])
        #expect(after.first?.availableActions == [])
        // A deployment that is not in progress has nothing to cancel.
        #expect(await !source.cancelDeployment(deploymentId: building.id, token: ""))
    }

    @Test("Remove stops the deployment that runs, and a rollback to it is then possible")
    func remove() async throws {
        let source = makeSource()
        let before = await source.fetchDeployments(
            projectId: "docs", environmentId: "docs-production", serviceId: "docs-site", token: "")
        let running = try #require(before.first)

        let didRemove = await source.removeDeployment(deploymentId: running.id, token: "")

        #expect(didRemove)
        let after = await source.fetchDeployments(
            projectId: "docs", environmentId: "docs-production", serviceId: "docs-site", token: "")
        #expect(after.first?.status == "REMOVED")
        #expect(after.first?.availableActions == [.rollback])
        #expect(await !source.removeDeployment(deploymentId: "missing", token: ""))
    }
}
