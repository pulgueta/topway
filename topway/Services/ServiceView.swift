import SwiftUI
import TopwayCore

/// One service in one environment. The Variables, Deployments and Metrics tabs are always
/// visible.
/// This view owns the steps below the projects list: the tabs, the variable editor and the logs.
struct ServiceView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let service: Service
    let project: Project
    let onDismiss: () -> Void
    let onDeleteService: () async -> Void

    @State private var destination: ServiceDestination = .overview
    @State private var tab: ServiceTab = .variables
    @State private var selectedEnvironmentId: String?
    @State private var variables: [EnvironmentVariable] = []
    @State private var isLoading = true
    @State private var areVariablesKnown = false
    @State private var latestLoadID = UUID()
    @State private var isRedeploying = false
    /// A new value makes the Deployments tab load again.
    @State private var deploymentsVersion = 0

    init(
        service: Service,
        project: Project,
        onDismiss: @escaping () -> Void,
        onDeleteService: @escaping () async -> Void
    ) {
        self.service = service
        self.project = project
        self.onDismiss = onDismiss
        self.onDeleteService = onDeleteService
        _selectedEnvironmentId = State(initialValue: project.environmentList.first?.id)
    }

    private var environments: [RailwayEnvironment] {
        project.environmentList
    }

    private var selectedEnvironmentName: String {
        environments.first { $0.id == selectedEnvironmentId }?.name ?? ""
    }

    var body: some View {
        ZStack {
            switch destination {
            case .overview:
                overview
                    .transition(.opacity)
            case .editVariable(let variable):
                EditVariableView(
                    projectId: project.id,
                    environmentId: selectedEnvironmentId ?? "",
                    serviceId: service.id,
                    serviceName: service.name,
                    environmentName: selectedEnvironmentName,
                    existingVariable: variable,
                    existingNames: areVariablesKnown ? Set(variables.map(\.name)) : nil,
                    onDismiss: { show(.overview) },
                    onSave: {
                        Task { await loadVariables() }
                    }
                )
                .transition(.screen(reduceMotion: reduceMotion))
            case .logs(let deployment):
                LogsView(
                    service: service,
                    deployment: deployment,
                    onDismiss: {
                        appState.clearError()
                        show(.overview)
                    }
                )
                .transition(.screen(reduceMotion: reduceMotion))
            }
        }
        // Runs at the start and for each new environment.
        .task(id: selectedEnvironmentId) {
            // The variables of the earlier environment must not show for the new one.
            variables = []
            await loadVariables()
        }
        // Escape goes back one step.
        .onExitCommand {
            if appState.pendingConfirmation != nil {
                appState.cancelConfirmation()
            } else if destination != .overview {
                appState.clearError()
                show(.overview)
            } else {
                onDismiss()
            }
        }
    }

    // MARK: - Overview

    private var overview: some View {
        Group {
            switch tab {
            case .variables:
                VariablesTab(
                    variables: variables,
                    isLoading: isLoading,
                    areVariablesKnown: areVariablesKnown,
                    onRetry: {
                        Task { await loadVariables() }
                    },
                    onAdd: { show(.editVariable(nil)) },
                    onEdit: { variable in show(.editVariable(variable)) }
                )
            case .deployments:
                DeploymentsView(
                    service: service,
                    project: project,
                    environmentId: selectedEnvironmentId ?? "",
                    reloadVersion: deploymentsVersion,
                    onViewLogs: { deployment in
                        appState.clearError()
                        show(.logs(deployment))
                    }
                )
                // The deployments of the earlier environment must not show for the new one.
                .id(selectedEnvironmentId)
            case .metrics:
                MetricsView(service: service, environmentId: selectedEnvironmentId ?? "")
                    // The metrics of the earlier environment must not show for the new one.
                    .id(selectedEnvironmentId)
            }
        }
        .safeAreaBar(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                ScreenHeader(title: service.name, backTitle: "Projects", onBack: { onDismiss() }) {
                    ServiceMenu(
                        serviceName: service.name,
                        isRedeploying: isRedeploying,
                        onRedeploy: { confirmRedeploy() },
                        onRequestDelete: { confirmDeleteService() }
                    )
                }

                ServiceContextBar(
                    projectName: project.name,
                    environments: environments,
                    selectedEnvironmentId: $selectedEnvironmentId,
                    tab: $tab
                )
            }
        }
        .onChange(of: tab) {
            // The error of one list does not belong to the other list.
            appState.clearError()
            // A failed load left no variables, so the tab tries again.
            if tab == .variables, !areVariablesKnown, !isLoading {
                Task { await loadVariables() }
            }
        }
    }

    // MARK: - Actions

    private func show(_ newDestination: ServiceDestination) {
        withAnimation(.screenChange) {
            destination = newDestination
        }
    }

    private func loadVariables() async {
        guard let environmentId = selectedEnvironmentId else {
            isLoading = false
            return
        }

        let loadID = UUID()
        latestLoadID = loadID
        isLoading = true
        areVariablesKnown = false
        let fetched = await appState.fetchVariables(
            projectId: project.id,
            environmentId: environmentId,
            serviceId: service.id
        )
        // Only the latest call may update the screen.
        guard loadID == latestLoadID else { return }
        variables = fetched ?? []
        areVariablesKnown = fetched != nil
        isLoading = false
    }

    private func confirmRedeploy() {
        appState.confirm(
            ConfirmationRequest(
                harm: .medium,
                title: "Redeploy \(service.name) in \(selectedEnvironmentName)?",
                message: "Railway builds and starts a new deployment of this service.",
                actionTitle: "Redeploy",
                environmentName: selectedEnvironmentName,
                perform: { await redeployService() }
            ))
    }

    private func confirmDeleteService() {
        appState.confirm(
            ConfirmationRequest(
                harm: .high,
                title: "Delete \(service.name)?",
                message:
                    "This removes the service and its deployments from all environments. "
                    + "You cannot undo this.",
                actionTitle: "Delete service",
                isDestructive: true,
                targetName: service.name,
                environmentName: project.productionEnvironmentName,
                perform: { await onDeleteService() }
            ))
    }

    /// Starts a redeploy, then shows the Deployments tab with the new deployment.
    private func redeployService() async {
        guard let environmentId = selectedEnvironmentId, !isRedeploying else { return }
        isRedeploying = true
        defer { isRedeploying = false }
        let didStart = await appState.redeployService(
            environmentId: environmentId, serviceId: service.id)
        if didStart {
            tab = .deployments
            deploymentsVersion += 1
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

    ServiceView(service: service, project: project, onDismiss: {}, onDeleteService: {})
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
