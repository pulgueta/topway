import Testing

@testable import TopwayCore

struct AlertSnapshotTests {
    @Test("A change to FAILED gives a deployment failed alert", arguments: ["SUCCESS", "BUILDING"])
    func failed(from earlier: String) {
        let alerts = alerts(across: [
            [status("web", earlier, deployment: "d1")], [status("web", "FAILED", deployment: "d2")],
        ])

        #expect(
            alerts == [
                HealthAlert(kind: .failed, service: status("web", "FAILED", deployment: "d2"))
            ])
    }

    @Test("A change to CRASHED gives a service crashed alert")
    func crashed() {
        let alerts = alerts(across: [[status("web", "SUCCESS")], [status("web", "CRASHED")]])

        #expect(alerts == [HealthAlert(kind: .crashed, service: status("web", "CRASHED"))])
    }

    @Test(
        "A change from FAILED or CRASHED to SUCCESS gives a recovered alert",
        arguments: ["FAILED", "CRASHED"])
    func recovered(from earlier: String) {
        let alerts = alerts(across: [
            [status("web", earlier, deployment: "d1")],
            [status("web", "SUCCESS", deployment: "d2")],
        ])

        #expect(
            alerts == [
                HealthAlert(kind: .recovered, service: status("web", "SUCCESS", deployment: "d2"))
            ])
    }

    @Test("A fix that builds first still gives a recovered alert")
    func recoveredAfterBuild() {
        let alerts = alerts(across: [
            [status("web", "FAILED", deployment: "d1")],
            [status("web", "BUILDING", deployment: "d2")],
            [status("web", "SUCCESS", deployment: "d2")],
        ])

        #expect(
            alerts == [
                HealthAlert(kind: .recovered, service: status("web", "SUCCESS", deployment: "d2"))
            ])
    }

    @Test("A new failed deployment after a failed deployment gives a new alert")
    func failedAgain() {
        let alerts = alerts(across: [
            [status("web", "FAILED", deployment: "d1")],
            [status("web", "BUILDING", deployment: "d2")],
            [status("web", "FAILED", deployment: "d2")],
        ])

        #expect(
            alerts == [
                HealthAlert(kind: .failed, service: status("web", "FAILED", deployment: "d2"))
            ])
    }

    @Test("A new failed deployment gives a new alert when no load sees it in progress")
    func failedAgainBetweenLoads() {
        let alerts = alerts(across: [
            [status("web", "FAILED", deployment: "d1")],
            [status("web", "FAILED", deployment: "d2")],
        ])

        #expect(
            alerts == [
                HealthAlert(kind: .failed, service: status("web", "FAILED", deployment: "d2"))
            ])
    }

    @Test("The same failed deployment gives no second alert")
    func sameFailedDeployment() {
        let alerts = alerts(across: [
            [status("web", "FAILED", deployment: "d1")],
            [status("web", "FAILED", deployment: "d1")],
        ])

        #expect(alerts.isEmpty)
    }

    @Test("A crashed deployment that deploys and crashes again gives no second alert")
    func sameCrashedDeployment() {
        let alerts = alerts(across: [
            [status("web", "CRASHED", deployment: "d1")],
            [status("web", "DEPLOYING", deployment: "d1")],
            [status("web", "CRASHED", deployment: "d1")],
        ])

        #expect(alerts.isEmpty)
    }

    @Test("A muted project gives no alerts, and other projects still give alerts")
    func mutedProject() {
        let alerts = alerts(
            across: [
                [status("web", "SUCCESS"), status("web", "SUCCESS", project: "blog")],
                [status("web", "CRASHED"), status("web", "CRASHED", project: "blog")],
            ], muted: ["shop"])

        #expect(alerts.map(\.service.projectId) == ["blog"])
    }

    @Test("The first snapshot gives no alerts")
    func firstSnapshot() {
        let alerts = alerts(across: [[status("web", "FAILED"), status("api", "CRASHED")]])

        #expect(alerts.isEmpty)
    }

    @Test(
        "A status that did not change, or a change with no alert, gives no alerts",
        arguments: [
            ("FAILED", "FAILED"), ("CRASHED", "CRASHED"), ("SUCCESS", "BUILDING"),
            ("FAILED", "BUILDING"), ("BUILDING", "SUCCESS"), ("SUCCESS", "REMOVED"),
        ])
    func noAlertChange(from earlier: String, to later: String) {
        let alerts = alerts(across: [[status("web", earlier)], [status("web", later)]])

        #expect(alerts.isEmpty)
    }

    @Test("A new service and a removed service give no alerts")
    func newAndRemovedServices() {
        let alerts = alerts(across: [
            [status("web", "SUCCESS"), status("old", "SUCCESS")],
            [status("web", "SUCCESS"), status("new", "CRASHED")],
        ])

        #expect(alerts.isEmpty)
    }

    /// Makes a snapshot from the first load, then updates it with each later load.
    /// - Returns: The alerts of all later loads.
    private func alerts(across loads: [[ServiceStatus]], muted: Set<String> = [])
        -> [HealthAlert]
    {
        var snapshot = AlertSnapshot(statuses: loads[0])
        return loads.dropFirst().flatMap {
            snapshot.update(with: $0, mutedProjectIds: muted)
        }
    }

    /// Makes the status of a service in the production environment of a project.
    private func status(
        _ service: String, _ status: String, deployment: String = "d1", project: String = "shop"
    ) -> ServiceStatus {
        ServiceStatus(
            projectId: project, projectName: project, environmentId: "\(project)-production",
            environmentName: "production", serviceId: "\(project)-\(service)",
            serviceName: service, deploymentId: deployment, status: status)
    }
}
