import Foundation
import Testing

@testable import TopwayCore

struct DeploymentActionTests {
    @Test(
        "A build or a deploy in progress has only Cancel",
        arguments: ["BUILDING", "DEPLOYING", "QUEUED", "WAITING", "INITIALIZING", "NEEDS_APPROVAL"])
    func inProgress(status: String) {
        #expect(make(status, canRollback: nil).availableActions == [.cancel])
        #expect(make(status, canRollback: true).availableActions == [.cancel])
    }

    @Test(
        "A deployment that runs, crashed or sleeps has Remove",
        arguments: ["SUCCESS", "CRASHED", "SLEEPING"])
    func active(status: String) {
        #expect(make(status, canRollback: nil).availableActions == [.remove])
        #expect(make(status, canRollback: false).availableActions == [.remove])
    }

    @Test(
        "Rollback shows only when Railway says that it is possible",
        arguments: [
            ("REMOVED", true, [DeploymentAction.rollback]),
            ("REMOVED", false, []),
            ("REMOVED", nil, []),
            ("FAILED", nil, []),
            ("SKIPPED", nil, []),
            ("SUCCESS", true, [.rollback, .remove]),
        ])
    func rollback(status: String, canRollback: Bool?, actions: [DeploymentAction]) {
        #expect(make(status, canRollback: canRollback).availableActions == actions)
    }

    @Test("A deployment that Railway removes at this time has no actions")
    func removing() {
        #expect(make("REMOVING", canRollback: true).availableActions == [])
    }

    @Test("The deployment reads canRollback from Railway, and a missing value is nil")
    func decoding() throws {
        let with = try JSONDecoder().decode(
            Deployment.self,
            from: Data(
                #"{"id":"d1","status":"REMOVED","staticUrl":null,"createdAt":"x","canRollback":true}"#
                    .utf8))
        let without = try JSONDecoder().decode(
            Deployment.self,
            from: Data(#"{"id":"d1","status":"REMOVED","staticUrl":null,"createdAt":"x"}"#.utf8))

        #expect(with.canRollback == true)
        #expect(without.canRollback == nil)
    }

    private func make(_ status: String, canRollback: Bool?) -> Deployment {
        Deployment(
            id: "d1", status: status, staticUrl: nil, createdAt: "2026-11-10T10:00:00Z",
            canRollback: canRollback)
    }
}
