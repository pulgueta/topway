import SwiftUI
import TopwayCore

struct VariablesView: View {
    @Environment(AppState.self) private var appState

    let service: Service
    let project: Project
    let onDismiss: () -> Void
    let onDeleteService: () async -> Void

    @State private var variables: [EnvironmentVariable] = []
    @State private var isLoading = true
    @State private var areVariablesKnown = false
    @State private var selectedEnvironmentId: String?
    @State private var copiedVariable: String?
    @State private var currentDestination: VariablesViewDestination = .list
    @State private var isRedeploying = false

    private var environments: [RailwayEnvironment] {
        project.environmentList
    }

    private var selectedEnvironmentName: String {
        environments.first { $0.id == selectedEnvironmentId }?.name ?? ""
    }

    var body: some View {
        ZStack {
            switch currentDestination {
            case .list:
                variablesListView
                    .transition(.opacity)
            case .edit(let variable):
                EditVariableView(
                    projectId: project.id,
                    environmentId: selectedEnvironmentId ?? "",
                    serviceId: service.id,
                    serviceName: service.name,
                    environmentName: selectedEnvironmentName,
                    existingVariable: variable,
                    existingNames: areVariablesKnown ? Set(variables.map(\.name)) : nil,
                    onDismiss: {
                        appState.clearError()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentDestination = .list
                        }
                    },
                    onSave: {
                        Task { await loadVariables() }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .deployments:
                DeploymentsView(
                    service: service,
                    project: project,
                    environmentId: selectedEnvironmentId ?? "",
                    onDismiss: {
                        appState.clearError()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentDestination = .list
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onChange(of: selectedEnvironmentId) { _, newValue in
            if newValue != nil {
                Task { await loadVariables() }
            }
        }
        .task {
            if selectedEnvironmentId == nil, let firstEnv = environments.first {
                selectedEnvironmentId = firstEnv.id
            }
            await loadVariables()
        }
        // Escape navigates back through the sub-stack before dismissing the view.
        .onExitCommand {
            if appState.pendingConfirmation != nil {
                appState.cancelConfirmation()
            } else if currentDestination != .list {
                appState.clearError()
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentDestination = .list
                }
            } else {
                onDismiss()
            }
        }
    }

    // MARK: - Variables List View

    private var variablesListView: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Service Info
            serviceInfoView

            Divider()

            // Environment Picker (if multiple environments)
            if environments.count > 1 {
                environmentPickerView
                Divider()
            }

            // Content
            contentView

            if let error = appState.errorMessage, !isLoading, !variables.isEmpty {
                ErrorBanner(message: error) { appState.clearError() }
            }

            Divider()

            // Footer
            footerView
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            BackButton { onDismiss() }

            Spacer()

            Text("Variables")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            // Service actions (Deployments, Redeploy, Delete)
            serviceMenu

            // Add variable button
            IconButton(icon: "plus", help: "Add variable") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentDestination = .edit(nil)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Service Menu

    private var serviceMenu: some View {
        Menu {
            Button("Deployments", systemImage: "arrow.triangle.2.circlepath") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentDestination = .deployments
                }
            }

            Button("Redeploy", systemImage: "arrow.counterclockwise") {
                confirmRedeploy()
            }
            .disabled(isRedeploying)

            Divider()

            Button("Delete service…", systemImage: "trash", role: .destructive) {
                confirmDeleteService()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(.rect(cornerRadius: 6))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Service actions")
        .accessibilityLabel("Service actions")
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

    // MARK: - Environment Picker

    private var environmentPickerView: some View {
        HStack {
            Text("Environment")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Picker("", selection: $selectedEnvironmentId) {
                ForEach(environments) { env in
                    Text(env.name).tag(Optional(env.id))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: 140)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            VStack(spacing: 12) {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                Text("Loading variables...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = appState.errorMessage, variables.isEmpty {
            ErrorStateView(message: error) {
                Task { await loadVariables() }
            }
        } else if variables.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "key.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)

                VStack(spacing: 4) {
                    Text("No Variables")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Add environment variables to configure your service.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentDestination = .edit(nil)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Add Variable")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.glassProminent)
                .controlSize(.small)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(variables) { variable in
                        VariableRow(
                            variable: variable,
                            isCopied: copiedVariable == variable.name,
                            onCopy: {
                                copyToClipboard(variable)
                            },
                            onEdit: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentDestination = .edit(variable)
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
            Text("\(variables.count) variable\(variables.count == 1 ? "" : "s")")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)

            Spacer()

            if !variables.isEmpty {
                CopyAllButton { copyAllToClipboard() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func loadVariables() async {
        guard let envId = selectedEnvironmentId else { return }

        isLoading = true
        areVariablesKnown = false
        variables = await appState.fetchVariables(
            projectId: project.id,
            environmentId: envId,
            serviceId: service.id
        )
        areVariablesKnown = appState.errorMessage == nil
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

    /// Triggers a redeploy, then jumps to the Deployments screen so the user
    /// can see the new deployment appear.
    private func redeployService() async {
        guard let envId = selectedEnvironmentId, !isRedeploying else { return }
        isRedeploying = true
        defer { isRedeploying = false }
        let didStart = await appState.redeployService(environmentId: envId, serviceId: service.id)
        if didStart {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentDestination = .deployments
            }
        }
    }

    private func copyToClipboard(_ variable: EnvironmentVariable) {
        Self.writeConcealed(variable.value)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedVariable = variable.name
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.2)) {
                if copiedVariable == variable.name {
                    copiedVariable = nil
                }
            }
        }
    }

    private func copyAllToClipboard() {
        let content =
            variables
            .map { "\($0.name)=\($0.value)" }
            .joined(separator: "\n")

        Self.writeConcealed(content)
    }

    /// Writes a secret to the pasteboard, marking it `org.nspasteboard.ConcealedType`
    /// so clipboard-history managers skip persisting it, while still pasting as
    /// plain text everywhere else.
    private static func writeConcealed(_ string: String) {
        let pasteboard = NSPasteboard.general
        let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        pasteboard.setString(string, forType: concealed)
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

    VariablesView(service: mockService, project: mockProject, onDismiss: {}, onDeleteService: {})
        .environment(AppState())
        .frame(width: 320, height: 400)
}
