import SwiftUI
import TopwayCore

/// The Deployments tab of the service screen: the list, its states and its actions.
struct DeploymentsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    let service: Service
    let project: Project
    let environmentId: String
    /// A new value loads the deployments again, for example after a redeploy from the Manage menu.
    var reloadVersion = 0
    let onViewLogs: (Deployment) -> Void

    @State private var deployments: [Deployment] = []
    @State private var isLoading = true
    @State private var isRedeploying = false
    @State private var restartingDeploymentId: String?
    @State private var latestLoadID = UUID()

    private var environmentName: String {
        project.environmentList.first { $0.id == environmentId }?.name ?? ""
    }

    private var deploymentCount: String {
        "\(deployments.count) deployment\(deployments.count == 1 ? "" : "s")"
    }

    var body: some View {
        ScreenLayout {
            content
        } top: {
            EmptyView()
        } bottom: {
            if let error = appState.errorMessage, !deployments.isEmpty {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        .task(id: reloadVersion) {
            await loadDeployments()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if !deployments.isEmpty {
            // The list stays while a reload runs, so the screen does not flash.
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(deployments) { deployment in
                        DeploymentRow(
                            deployment: deployment,
                            isRestarting: restartingDeploymentId == deployment.id,
                            onRestart: { confirmRestart(deployment) },
                            onOpenURL: { open(deployment) },
                            onViewLogs: { onViewLogs(deployment) }
                        )
                    }
                }
            }
        } else if isLoading {
            LoadingStateView(title: "Loading deployments…")
        } else if let error = appState.errorMessage {
            ErrorStateView(title: "Deployments did not load", message: error) {
                Task { await loadDeployments() }
            }
        } else {
            ContentUnavailableView(
                "No deployments",
                systemImage: "arrow.triangle.2.circlepath",
                description: Text(
                    "This service has no deployments in this environment. Select Redeploy to start one."
                )
            )
        }
    }

    // MARK: - Footer

    private var footer: some View {
        ActionBar {
            if !isLoading || !deployments.isEmpty {
                Text(deploymentCount)
            }
        } actions: {
            Button("Refresh", systemImage: "arrow.clockwise") {
                Task { await loadDeployments() }
            }
            .buttonStyle(.glass)
            .disabled(isLoading)
            .help("Load the deployments again.")

            Button(isRedeploying ? "Redeploying…" : "Redeploy") { confirmRedeploy() }
                .buttonStyle(.glassProminent)
                .disabled(isRedeploying)
                .help("Build and start a new deployment of \(service.name).")
        }
    }

    // MARK: - Actions

    private func open(_ deployment: Deployment) {
        if let host = deployment.staticUrl, let url = URL(string: "https://\(host)") {
            openURL(url)
        }
    }

    private func confirmRestart(_ deployment: Deployment) {
        appState.confirm(
            ConfirmationRequest(
                harm: .medium,
                title: "Restart \(service.name) in \(environmentName)?",
                message: "The service stops for a short time.",
                actionTitle: "Restart",
                environmentName: environmentName,
                perform: { await restartDeployment(deployment) }
            ))
    }

    private func confirmRedeploy() {
        appState.confirm(
            ConfirmationRequest(
                harm: .medium,
                title: "Redeploy \(service.name) in \(environmentName)?",
                message: "Railway builds and starts a new deployment of this service.",
                actionTitle: "Redeploy",
                environmentName: environmentName,
                perform: { await triggerRedeploy() }
            ))
    }

    private func loadDeployments() async {
        let loadID = UUID()
        latestLoadID = loadID
        isLoading = true
        let fetched = await appState.fetchDeployments(
            projectId: project.id,
            environmentId: environmentId,
            serviceId: service.id
        )
        // Only the latest call may update the screen.
        guard loadID == latestLoadID else { return }
        deployments = fetched
        isLoading = false
    }

    private func restartDeployment(_ deployment: Deployment) async {
        restartingDeploymentId = deployment.id
        let success = await appState.restartDeployment(deploymentId: deployment.id)
        restartingDeploymentId = nil
        // The list then shows the new status.
        if success {
            await loadDeployments()
        }
    }

    private func triggerRedeploy() async {
        isRedeploying = true
        let success = await appState.redeployService(
            environmentId: environmentId,
            serviceId: service.id
        )
        isRedeploying = false
        // The list then shows the new deployment.
        if success {
            await loadDeployments()
        }
    }
}

#Preview {
    let service = Service(id: "1", name: "web-app")
    let project = Project(
        id: "1",
        name: "My Project",
        services: ServiceConnection(edges: [ServiceEdge(node: service)]),
        environments: EnvironmentConnection(edges: [
            EnvironmentEdge(node: RailwayEnvironment(id: "env1", name: "production"))
        ])
    )

    DeploymentsView(service: service, project: project, environmentId: "env1", onViewLogs: { _ in })
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
