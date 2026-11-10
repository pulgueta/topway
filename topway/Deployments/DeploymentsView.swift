import SwiftUI
import TopwayCore

@MainActor
struct DeploymentsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    let service: Service
    let project: Project
    let environmentId: String
    let onDismiss: () -> Void

    @State private var deployments: [Deployment] = []
    @State private var isLoading = true
    @State private var isRedeploying = false
    @State private var restartingDeploymentId: String?

    private var environmentName: String {
        project.environmentList.first { $0.id == environmentId }?.name ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Service Info
            serviceInfoView

            Divider()

            // Content
            contentView

            if let error = appState.errorMessage, !isLoading, !deployments.isEmpty {
                ErrorBanner(message: error) { appState.clearError() }
            }

            Divider()

            // Footer
            footerView
        }
        .task {
            await loadDeployments()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            BackButton { onDismiss() }

            Spacer()

            Text("Deployments")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            // Refresh button
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                    .frame(width: 24, height: 24)
            } else {
                IconButton(
                    icon: "arrow.clockwise",
                    help: "Refresh"
                ) {
                    Task { await loadDeployments() }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Service Info

    private var serviceInfoView: some View {
        HStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 12))
                .foregroundStyle(.blue)

            Text(service.name)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            Text(project.name)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            VStack(spacing: 12) {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                Text("Loading deployments...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = appState.errorMessage, deployments.isEmpty {
            ErrorStateView(message: error) {
                Task { await loadDeployments() }
            }
        } else if deployments.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)

                VStack(spacing: 4) {
                    Text("No Deployments")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Deploy your service to see deployment history here.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                Button {
                    confirmRedeploy()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                        Text("Deploy Now")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.glassProminent)
                .controlSize(.small)
                .disabled(isRedeploying)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(deployments) { deployment in
                        DeploymentRow(
                            deployment: deployment,
                            isRestarting: restartingDeploymentId == deployment.id,
                            onRestart: {
                                confirmRestart(deployment)
                            },
                            onOpenURL: {
                                if let urlString = deployment.staticUrl,
                                    let url = URL(string: "https://\(urlString)")
                                {
                                    openURL(url)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Text("\(deployments.count) deployment\(deployments.count == 1 ? "" : "s")")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)

            Spacer()

            // Redeploy button
            RedeployButton(isLoading: isRedeploying) {
                confirmRedeploy()
            }
            .disabled(isRedeploying)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

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
        isLoading = true
        deployments = await appState.fetchDeployments(
            projectId: project.id,
            environmentId: environmentId,
            serviceId: service.id
        )
        isLoading = false
    }

    private func restartDeployment(_ deployment: Deployment) async {
        restartingDeploymentId = deployment.id
        let success = await appState.restartDeployment(deploymentId: deployment.id)
        restartingDeploymentId = nil
        // Reload deployments to see updated status
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
        // Reload deployments to see the new one
        if success {
            await loadDeployments()
        }
    }
}

#Preview {
    let mockService = Service(id: "1", name: "web-app")
    let mockProject = Project(
        id: "1",
        name: "My Project",
        services: ServiceConnection(edges: [ServiceEdge(node: mockService)]),
        environments: EnvironmentConnection(edges: [
            EnvironmentEdge(node: RailwayEnvironment(id: "env1", name: "production"))
        ])
    )

    DeploymentsView(
        service: mockService,
        project: mockProject,
        environmentId: "env1",
        onDismiss: {}
    )
    .environment(AppState())
    .frame(width: 320, height: 400)
}
