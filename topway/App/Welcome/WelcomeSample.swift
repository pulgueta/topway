import SwiftUI
import TopwayCore

/// The data of the copies of the app in the welcome window. It comes from a new
/// `SampleDataSource`, which keeps its data in memory and sends no request. The welcome
/// window does not use the `AppState` of the app, so it changes no setting and no sign-in.
struct WelcomeSample {
    /// The sample projects, with the latest deployment of each service.
    let projects: [Project]
    /// The deployments of `service` in `environment`, newest first.
    let deployments: [Deployment]

    /// The first sample project. The deployments belong to it.
    var project: Project? { projects.first }
    var environment: RailwayEnvironment? { project?.environmentList.first }
    var service: Service? { project?.serviceList.first }

    /// One health for each state of the menu bar icon: healthy, in progress and failing.
    /// Each comes from the sample projects and from the rule of `HealthSummary`, so the
    /// icon is the real `MenuBarLabel`. No projects give healthy. One environment of a
    /// project can be in progress while all projects fail.
    var healthStates: [HealthSummary] {
        let summaries =
            [HealthSummary(projects: [])]
            + environmentProjects.map { HealthSummary(projects: [$0]) }
            + [HealthSummary(projects: projects)]
        return [Health.healthy, .inProgress, .failing].compactMap { health in
            summaries.first { $0.health == health }
        }
    }

    /// Each sample project in each of its environments, as a project with one environment.
    private var environmentProjects: [Project] {
        projects.flatMap { project in
            let services = ServiceConnection(
                edges: project.serviceList.map { ServiceEdge(node: $0) })
            return project.environmentList.map { environment in
                Project(
                    id: project.id, name: project.name, services: services,
                    environments: EnvironmentConnection(edges: [EnvironmentEdge(node: environment)])
                )
            }
        }
    }

    /// Reads the sample data. The sample source has no token and no workspace.
    static func load() async -> WelcomeSample {
        let source = SampleDataSource()
        let projects = await source.fetchProjects(workspaceId: "", token: "")
        var deployments: [Deployment] = []
        if let project = projects.first, let environment = project.environmentList.first,
            let service = project.serviceList.first
        {
            deployments = await source.fetchDeployments(
                projectId: project.id, environmentId: environment.id, serviceId: service.id,
                token: "")
        }
        return WelcomeSample(projects: projects, deployments: deployments)
    }
}
