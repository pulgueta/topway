import SwiftUI
import TopwayCore

/// Adds an environment to a project. The environment is empty, or a copy of an environment
/// that the user selects.
struct NewEnvironmentView: View {
    @Environment(AppState.self) private var appState

    let projectId: String
    let projectName: String
    let environments: [RailwayEnvironment]
    let onDismiss: () -> Void

    @State private var name = ""
    /// `nil` makes an empty environment.
    @State private var sourceEnvironmentId: String?
    @State private var isCreating = false
    @FocusState private var isNameFocused: Bool

    private var problem: EnvironmentNameProblem? {
        EnvironmentRules.problem(name: name, existingNames: environments.map(\.name))
    }

    private var sourceName: String? {
        environments.first { $0.id == sourceEnvironmentId }?.name
    }

    var body: some View {
        ScreenLayout {
            form
        } top: {
            ScreenHeader(
                title: "New environment", backTitle: "Environments", onBack: { cancel() }
            )
            .disabled(isCreating)
        } bottom: {
            if let error = appState.errorMessage {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        .onAppear {
            isNameFocused = true
        }
        // Escape obeys the same rule as Cancel.
        .onExitCommand {
            if appState.pendingConfirmation != nil {
                appState.cancelConfirmation()
            } else {
                cancel()
            }
        }
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label(projectName, systemImage: "folder")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityLabel("Project: \(projectName)")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.callout.weight(.medium))

                    TextField("Name", text: $name, prompt: Text("staging"))
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .focused($isNameFocused)
                        .onSubmit { confirmCreate() }

                    if let message = problem?.message {
                        Label {
                            Text(message)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        .font(.subheadline)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Copy from")
                        .font(.callout.weight(.medium))

                    Picker("Copy from", selection: $sourceEnvironmentId) {
                        Text("No environment").tag(String?.none)
                        ForEach(environments) { environment in
                            Text(environment.name).tag(Optional(environment.id))
                        }
                    }
                    .labelsHidden()
                    .fixedSize()

                    Text(
                        sourceEnvironmentId == nil
                            ? "The new environment is empty. It has no services and no variables."
                            : "Railway copies the services, the variables and the settings. The services then deploy in the new environment."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, Layout.controlSpacing)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        ActionBar {
            if isCreating {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Creating the environment")
            }
        } actions: {
            Button("Cancel") { cancel() }
                .buttonStyle(.glass)
                .disabled(isCreating)

            Button(isCreating ? "Creating…" : "Create environment") { confirmCreate() }
                .buttonStyle(.glassProminent)
                .disabled(problem != nil || isCreating)
        }
    }

    // MARK: - Actions

    private func cancel() {
        guard !isCreating else { return }
        onDismiss()
    }

    /// The dialog uses the values from when it opened.
    private func confirmCreate() {
        guard problem == nil, !isCreating else { return }
        let cleanName = EnvironmentRules.cleanName(name)
        let sourceId = sourceEnvironmentId
        let source = sourceName ?? ""
        appState.confirm(
            ConfirmationRequest(
                harm: EnvironmentRules.createHarm(hasSource: sourceId != nil),
                title: "Create \(cleanName) as a copy of \(source)?",
                message:
                    "Railway copies the services, the variables and the settings of \(source) "
                    + "in \(projectName). The services then deploy, and Railway bills their usage.",
                actionTitle: "Create environment",
                perform: { await create(name: cleanName, sourceEnvironmentId: sourceId) }
            ))
    }

    private func create(name: String, sourceEnvironmentId: String?) async {
        isCreating = true
        let didCreate = await appState.createEnvironment(
            projectId: projectId, name: name, sourceEnvironmentId: sourceEnvironmentId)
        isCreating = false
        if didCreate {
            onDismiss()
        }
    }
}

#Preview {
    NewEnvironmentView(
        projectId: "1", projectName: "My Project",
        environments: [RailwayEnvironment(id: "env1", name: "production")], onDismiss: {}
    )
    .environment(AppState())
    .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
