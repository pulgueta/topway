import Testing

@testable import TopwayCore

struct AlertRulesTests {
    @Test("A change to FAILED gives a deployment failed alert", arguments: ["SUCCESS", "BUILDING"])
    func failed(from earlier: String) {
        let alerts = AlertRules.alerts(
            from: [status("web", earlier)], to: [status("web", "FAILED")], mutedProjectIds: [])

        #expect(alerts == [HealthAlert(kind: .failed, service: status("web", "FAILED"))])
    }

    @Test("A change to CRASHED gives a service crashed alert")
    func crashed() {
        let alerts = AlertRules.alerts(
            from: [status("web", "SUCCESS")], to: [status("web", "CRASHED")], mutedProjectIds: [])

        #expect(alerts == [HealthAlert(kind: .crashed, service: status("web", "CRASHED"))])
    }

    @Test(
        "A change from FAILED or CRASHED to SUCCESS gives a recovered alert",
        arguments: ["FAILED", "CRASHED"])
    func recovered(from earlier: String) {
        let alerts = AlertRules.alerts(
            from: [status("web", earlier)], to: [status("web", "SUCCESS")], mutedProjectIds: [])

        #expect(alerts == [HealthAlert(kind: .recovered, service: status("web", "SUCCESS"))])
    }

    @Test("A muted project gives no alerts, and other projects still give alerts")
    func mutedProject() {
        let alerts = AlertRules.alerts(
            from: [status("web", "SUCCESS"), status("web", "SUCCESS", project: "blog")],
            to: [status("web", "CRASHED"), status("web", "CRASHED", project: "blog")],
            mutedProjectIds: ["shop"])

        #expect(alerts.map(\.service.projectId) == ["blog"])
    }

    @Test("The first snapshot gives no alerts")
    func firstSnapshot() {
        let alerts = AlertRules.alerts(
            from: nil, to: [status("web", "FAILED"), status("api", "CRASHED")], mutedProjectIds: [])

        #expect(alerts.isEmpty)
    }

    @Test(
        "A status that did not change, or a change with no alert, gives no alerts",
        arguments: [
            ("FAILED", "FAILED"), ("CRASHED", "CRASHED"), ("SUCCESS", "BUILDING"),
            ("FAILED", "BUILDING"), ("BUILDING", "SUCCESS"), ("SUCCESS", "REMOVED"),
        ])
    func noAlertChange(from earlier: String, to later: String) {
        let alerts = AlertRules.alerts(
            from: [status("web", earlier)], to: [status("web", later)], mutedProjectIds: [])

        #expect(alerts.isEmpty)
    }

    @Test("A new service and a removed service give no alerts")
    func newAndRemovedServices() {
        let alerts = AlertRules.alerts(
            from: [status("web", "SUCCESS"), status("old", "SUCCESS")],
            to: [status("web", "SUCCESS"), status("new", "CRASHED")], mutedProjectIds: [])

        #expect(alerts.isEmpty)
    }

    /// Makes the status of a service in the production environment of a project.
    private func status(_ service: String, _ status: String, project: String = "shop")
        -> ServiceStatus
    {
        ServiceStatus(
            projectId: project, projectName: project, environmentId: "\(project)-production",
            environmentName: "production", serviceId: "\(project)-\(service)",
            serviceName: service, status: status)
    }
}
