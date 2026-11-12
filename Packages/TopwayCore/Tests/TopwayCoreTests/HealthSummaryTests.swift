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
            ("NEEDS_APPROVAL", .inProgress),
            ("REMOVING", .inProgress),
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

    @Test(
        "The status description says the health in words, and is nil when all is healthy",
        arguments: [
            (["SUCCESS", "SLEEPING"], String?.none),
            ([], nil),
            (["SUCCESS", "BUILDING"], "build or deploy in progress"),
            (["DEPLOYING", "FAILED"], "1 service failing"),
            (["CRASHED", "FAILED", "SUCCESS"], "2 services failing"),
        ])
    func statusDescription(statuses: [String], expected: String?) {
        let summary = HealthSummary(projects: [makeProject("shop", statuses: statuses)])

        #expect(summary.statusDescription == expected)
    }

    /// Makes a project with one production environment and one service for each status.
    private func makeProject(_ name: String, statuses: [String]) -> Project {
        let services = statuses.indices.map { Service(id: "\(name)-s\($0)", name: "s\($0)") }
        let environment = RailwayEnvironment(
            id: "\(name)-production", name: "production",
            instances: zip(services, statuses).enumerated().map { index, pair in
                ServiceInstance(
                    serviceId: pair.0.id,
                    latestDeployment: Deployment(
                        id: "\(name)-d\(index)", status: pair.1, staticUrl: nil,
                        createdAt: "2026-11-10T10:00:00Z"))
            })
        return Project(
            id: name, name: name,
            services: ServiceConnection(edges: services.map { ServiceEdge(node: $0) }),
            environments: EnvironmentConnection(edges: [EnvironmentEdge(node: environment)]))
    }
}
