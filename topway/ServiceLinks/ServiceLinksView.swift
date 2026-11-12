import SwiftUI
import TopwayCore

/// The links between the services of a project in one environment, as text: for each
/// service, the services that it uses and the services that use it. It is read-only.
/// A text list stays readable for 2 to 15 services, and VoiceOver reads each link.
struct ServiceLinksView: View {
    @Environment(AppState.self) private var appState

    let project: Project
    let onDismiss: () -> Void

    @State private var environmentId: String?
    /// `nil` until the first load ends with a result.
    @State private var graph: ServiceGraph?
    @State private var isLoading = true
    @State private var latestLoadID = UUID()

    init(project: Project, onDismiss: @escaping () -> Void) {
        self.project = project
        self.onDismiss = onDismiss
        _environmentId = State(initialValue: project.environmentList.first?.id)
    }

    private var environments: [RailwayEnvironment] {
        project.environmentList
    }

    private var linkCount: String {
        let count = graph?.edges.count ?? 0
        return "\(count) link\(count == 1 ? "" : "s")"
    }

    var body: some View {
        ScreenLayout {
            content
        } top: {
            ScreenHeader(title: "Service links", backTitle: "Projects", onBack: { onDismiss() })
            context
        } bottom: {
            // With a list, the error belongs to a refresh. The list of the last load stays.
            if let error = appState.errorMessage, graph != nil {
                ErrorBanner(message: error) { appState.clearError() }
            }

            ActionBar {
                if graph != nil {
                    Text(linkCount)
                }
            } actions: {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task { await load() }
                }
                .buttonStyle(.glass)
                .disabled(isLoading || environmentId == nil)
                .help("Load the links again.")
            }
        }
        // Runs at the start and for each new environment.
        .task(id: environmentId) {
            // The links of the earlier environment must not show for the new one.
            graph = nil
            await load()
        }
        // A reload can remove the selected environment, for example after a delete.
        .onChange(of: environments.map(\.id)) { _, ids in
            selectAvailableEnvironment(in: ids)
        }
        // Escape goes back one step.
        .onExitCommand { onDismiss() }
    }

    private var context: some View {
        HStack(spacing: Layout.controlSpacing) {
            Label(project.name, systemImage: "folder")
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .accessibilityLabel("Project: \(project.name)")

            Spacer(minLength: Layout.controlSpacing)

            if environments.count > 1 {
                Picker("Environment", selection: $environmentId) {
                    ForEach(environments) { environment in
                        Text(environment.name).tag(Optional(environment.id))
                    }
                }
                .fixedSize()
                .help("The links below belong to this environment.")
            } else if let environment = environments.first {
                Text("Environment: \(environment.name)")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .font(.callout)
        .padding(.horizontal, Layout.barPadding)
        .padding(.bottom, Layout.controlSpacing)
    }

    @ViewBuilder
    private var content: some View {
        if environmentId == nil {
            ContentUnavailableView(
                "No environments",
                systemImage: "square.stack.3d.up",
                description: Text(
                    "This project has no environments. Add one in Manage > Environments.")
            )
        } else if let graph {
            if graph.services.isEmpty {
                ContentUnavailableView(
                    "No services",
                    systemImage: "cube",
                    description: Text("This environment has no services.")
                )
            } else if graph.edges.isEmpty {
                ContentUnavailableView(
                    "No links",
                    systemImage: "link",
                    description: Text(
                        "No service in this environment uses a variable of a different service "
                            + "or a shared variable.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(graph.nodes, id: \.self) { node in
                            ServiceLinkSection(graph: graph, node: node)
                        }
                    }
                }
            }
        } else if isLoading {
            LoadingStateView(title: "Loading links…")
        } else {
            ErrorStateView(
                title: "Links did not load",
                message: appState.errorMessage ?? "Select Try again to load the links."
            ) {
                Task { await load() }
            }
        }
    }

    /// When the selected environment is gone, the links and the load of that environment
    /// stop, and the first available environment loads.
    private func selectAvailableEnvironment(in ids: [String]) {
        let selection = EnvironmentSelection.reconciled(environmentId, available: ids)
        guard selection != environmentId else { return }
        // A load that is in progress belongs to the earlier environment.
        latestLoadID = UUID()
        graph = nil
        environmentId = selection
    }

    private func load() async {
        guard let environmentId else {
            isLoading = false
            return
        }

        let loadID = UUID()
        latestLoadID = loadID
        isLoading = true
        let services = project.serviceList(in: environmentId)
        let variables = await appState.fetchProjectVariables(
            projectId: project.id, environmentId: environmentId, serviceIds: services.map(\.id))
        // Only the latest call may update the screen.
        guard loadID == latestLoadID else { return }
        if let variables {
            graph = ServiceGraph(services: services, variables: variables)
        }
        isLoading = false
    }
}

#Preview {
    let project = Project(
        id: "1",
        name: "My Project",
        services: ServiceConnection(edges: [ServiceEdge(node: Service(id: "s1", name: "web"))]),
        environments: EnvironmentConnection(edges: [
            EnvironmentEdge(node: RailwayEnvironment(id: "env1", name: "production"))
        ])
    )

    ServiceLinksView(project: project, onDismiss: {})
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
