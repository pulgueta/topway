import SwiftUI
import TopwayCore

/// Adds a service to a project from a GitHub repository, a Docker image or a database
/// template of Railway.
struct AddServiceView: View {
    @Environment(AppState.self) private var appState

    let projectId: String
    let projectName: String
    let onDismiss: () -> Void

    @State private var sourceType: ServiceSourceType = .gitHub
    @State private var repoName: String = ""
    @State private var imageName: String = ""
    @State private var database: DatabaseTemplate = .postgres
    /// The environment where the database starts.
    @State private var databaseEnvironmentId: String?
    @State private var isCreating = false
    @FocusState private var isSourceFocused: Bool

    private var sourceValue: String {
        sourceType == .gitHub ? repoName : imageName
    }

    private var environments: [RailwayEnvironment] {
        appState.projects.first { $0.id == projectId }?.environmentList ?? []
    }

    private var databaseEnvironment: RailwayEnvironment? {
        environments.first { $0.id == databaseEnvironmentId }
    }

    private var isInputValid: Bool {
        if sourceType == .database {
            return databaseEnvironment != nil
        }
        return !sourceValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScreenLayout {
            form
        } top: {
            ScreenHeader(title: "Add service", backTitle: "Projects", onBack: { cancel() })
                .disabled(isCreating)
        } bottom: {
            if let error = appState.errorMessage {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        .onAppear {
            isSourceFocused = true
            // A database starts in production, if the project has that environment.
            databaseEnvironmentId =
                (environments.first { ConfirmationRules.isProduction(environmentName: $0.name) }
                ?? environments.first)?.id
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
                    Text("Source")
                        .font(.callout.weight(.medium))

                    Picker("Source", selection: $sourceType) {
                        Text("GitHub repository").tag(ServiceSourceType.gitHub)
                        Text("Docker image").tag(ServiceSourceType.docker)
                        Text("Database").tag(ServiceSourceType.database)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                if sourceType == .database {
                    databaseFields
                } else {
                    sourceField
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, Layout.controlSpacing)
        }
    }

    private var sourceField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sourceType == .gitHub ? "Repository" : "Image")
                .font(.callout.weight(.medium))

            TextField(
                sourceType == .gitHub ? "Repository" : "Image",
                text: sourceType == .gitHub ? $repoName : $imageName,
                prompt: Text(sourceType == .gitHub ? "owner/repository" : "image:tag")
            )
            .textFieldStyle(.roundedBorder)
            .font(.body.monospaced())
            .autocorrectionDisabled()
            .focused($isSourceFocused)
            .onSubmit { createService() }

            Text(
                sourceType == .gitHub
                    ? "Example: railwayapp-templates/django. Railway must have access to the repository."
                    : "Example: nginx:latest."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var databaseFields: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Database")
                .font(.callout.weight(.medium))

            Picker("Database", selection: $database) {
                ForEach(DatabaseTemplate.allCases) { template in
                    Text(template.title).tag(template)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
        }

        VStack(alignment: .leading, spacing: 6) {
            Text("Environment")
                .font(.callout.weight(.medium))

            if environments.isEmpty {
                Text("This project has no environment. Add one in Manage > Environments.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Picker("Environment", selection: $databaseEnvironmentId) {
                    ForEach(environments) { environment in
                        Text(environment.name).tag(Optional(environment.id))
                    }
                }
                .labelsHidden()
                .fixedSize()
            }

            Text(
                "Railway adds a service from its template, with a volume and the connection variables, and starts it in this environment."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        ActionBar {
            if isCreating {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Adding the service")
            }
        } actions: {
            Button("Cancel") { cancel() }
                .buttonStyle(.glass)
                .disabled(isCreating)

            Button(
                isCreating ? "Adding…" : sourceType == .database ? "Add database" : "Add service"
            ) {
                createService()
            }
            .buttonStyle(.glassProminent)
            .disabled(!isInputValid || isCreating)
        }
    }

    // MARK: - Actions

    // Only a user exit clears the error. A failed refresh must stay visible.
    // The screen stays while Railway adds the service, so the result shows here.
    private func cancel() {
        guard !isCreating else { return }
        appState.clearError()
        onDismiss()
    }

    /// A database costs money from its start, so it asks for a confirmation that names the
    /// project and the environment. The dialog uses the values from when it opened.
    private func confirmDatabase() {
        guard let environment = databaseEnvironment else { return }
        let template = database
        appState.confirm(
            ConfirmationRequest(
                harm: .medium,
                title: "Add \(template.title) to \(projectName) in \(environment.name)?",
                message:
                    "Railway adds a database service with a volume and starts it. "
                    + "Railway bills its usage.",
                actionTitle: "Add database",
                environmentName: environment.name,
                perform: { await addDatabase(template, environmentId: environment.id) }
            ))
    }

    private func addDatabase(_ template: DatabaseTemplate, environmentId: String) async {
        isCreating = true
        let didAdd = await appState.deployDatabase(
            template, projectId: projectId, environmentId: environmentId)
        isCreating = false
        if didAdd {
            onDismiss()
        }
    }

    private func createService() {
        guard isInputValid, !isCreating else { return }
        guard sourceType != .database else {
            confirmDatabase()
            return
        }
        isCreating = true
        appState.clearError()

        Task {
            let success: Bool
            if sourceType == .gitHub {
                success = await appState.createService(
                    projectId: projectId,
                    repo: repoName.trimmingCharacters(in: .whitespaces)
                )
            } else {
                success = await appState.createServiceWithImage(
                    projectId: projectId,
                    image: imageName.trimmingCharacters(in: .whitespaces)
                )
            }

            isCreating = false

            if success {
                onDismiss()
            }
        }
    }
}

#Preview {
    AddServiceView(projectId: "123", projectName: "My Project", onDismiss: {})
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
