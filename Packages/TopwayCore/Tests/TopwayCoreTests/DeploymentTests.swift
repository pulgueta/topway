import Foundation
import Testing
import TopwayCore

struct DeploymentTests {
    @Test(
        "Status gives display text and a color name",
        arguments: [
            ("SUCCESS", "Running", "green"),
            ("BUILDING", "Building", "yellow"),
            ("DEPLOYING", "Deploying", "yellow"),
            ("FAILED", "Failed", "red"),
            ("CRASHED", "Crashed", "red"),
            ("REMOVED", "Removed", "gray"),
            ("SLEEPING", "Sleeping", "purple"),
            ("QUEUED", "Queued", "yellow"),
            ("WAITING", "Waiting", "yellow"),
            ("SKIPPED", "Skipped", "gray"),
            ("UNKNOWN_STATE", "Unknown_State", "gray"),
        ])
    func statusMapping(status: String, display: String, color: String) throws {
        let deployment = try makeDeployment(status: status, createdAt: "2026-01-15T10:00:00Z")

        #expect(deployment.statusDisplay == display)
        #expect(deployment.statusColor == color)
    }

    @Test("A date that does not parse stays unchanged")
    func unparsableDate() throws {
        let deployment = try makeDeployment(status: "SUCCESS", createdAt: "not-a-date")

        #expect(deployment.formattedDate == "not-a-date")
    }

    private func makeDeployment(status: String, createdAt: String) throws -> Deployment {
        let json = """
            {"id": "d1", "status": "\(status)", "staticUrl": null, "createdAt": "\(createdAt)"}
            """
        return try JSONDecoder().decode(Deployment.self, from: Data(json.utf8))
    }
}
