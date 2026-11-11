import Testing

@testable import TopwayCore

struct HealthSummaryTests {
    @Test(
        "The latest status of a service sets its health group",
        arguments: [
            ("FAILED", Health.failing),
            ("CRASHED", .failing),
            ("BUILDING", .inProgress),
            ("DEPLOYING", .inProgress),
            ("INITIALIZING", .inProgress),
            ("QUEUED", .inProgress),
            ("WAITING", .inProgress),
            ("SUCCESS", .healthy),
            ("REMOVED", .healthy),
            ("SKIPPED", .healthy),
            ("SLEEPING", .healthy),
            ("UNKNOWN_STATE", .healthy),
        ])
    func statusGroup(status: String, expected: Health) {
        let summary = HealthSummary(projects: [makeProject("shop", statuses: [status])])

        #expect(summary.health == expected)
        #expect(summary.failing.map(\.serviceName) == (expected == .failing ? ["s0"] : []))
    }

    @Test("A failing service sets the health to failing, before a service in progress")
    func mixedStatuses() {
        let summary = HealthSummary(projects: [
            makeProject("shop", statuses: ["SUCCESS", "BUILDING", "CRASHED"]),
            makeProject("blog", statuses: ["FAILED", "SLEEPING"]),
        ])

        #expect(summary.health == .failing)
        #expect(
            summary.failing.map { "\($0.projectName)/\($0.environmentName)/\($0.serviceName)" }
                == ["shop/production/s2", "blog/production/s0"])
        #expect(
            HealthSummary(projects: [makeProject("shop", statuses: ["SUCCESS", "QUEUED"])]).health
                == .inProgress)
    }

    @Test("No projects, or no deployments, give healthy with no failing services")
    func emptyList() {
        for projects in [[], [makeProject("shop", statuses: [])]] {
            let summary = HealthSummary(projects: projects)

            #expect(summary.health == .healthy)
            #expect(summary.failing.isEmpty)
        }
    }

    /// Makes a project with one production environment and one service for each status.
    private func makeProject(_ name: String, statuses: [String]) -> Project {
        let environment = RailwayEnvironment(id: "\(name)-production", name: "production")
        let services = statuses.enumerated().map { index, status in
            Service(
                id: "\(name)-s\(index)", name: "s\(index)",
                instances: [
                    ServiceInstance(
                        environmentId: environment.id,
                        latestDeployment: Deployment(
                            id: "\(name)-d\(index)", status: status, staticUrl: nil,
                            createdAt: "2026-11-10T10:00:00Z"))
                ])
        }
        return Project(
            id: name, name: name,
            services: ServiceConnection(edges: services.map { ServiceEdge(node: $0) }),
            environments: EnvironmentConnection(edges: [EnvironmentEdge(node: environment)]))
    }
}
