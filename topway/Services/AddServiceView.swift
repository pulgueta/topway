import SwiftUI

/// Adds a service to a project from a GitHub repository or a Docker image.
struct AddServiceView: View {
    @Environment(AppState.self) private var appState

    let projectId: String
    let projectName: String
    let onDismiss: () -> Void

    @State private var sourceType: ServiceSourceType = .gitHub
    @State private var repoName: String = ""
    @State private var imageName: String = ""
    @State private var isCreating = false
    @FocusState private var isSourceFocused: Bool

    private var sourceValue: String {
        sourceType == .gitHub ? repoName : imageName
    }

    private var isInputValid: Bool {
        !sourceValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScreenLayout {
            form
        } top: {
            ScreenHeader(title: "Add service", backTitle: "Projects", onBack: { cancel() })
        } bottom: {
            if let error = appState.errorMessage {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        .onAppear {
            isSourceFocused = true
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
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

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
                    .accessibilityLabel("Adding the service")
            }
        } actions: {
            Button("Cancel") { cancel() }
                .buttonStyle(.glass)

            Button(isCreating ? "Adding…" : "Add service") { createService() }
                .buttonStyle(.glassProminent)
                .disabled(!isInputValid || isCreating)
        }
    }

    // MARK: - Actions

    // Only a user exit clears the error. A failed refresh must stay visible.
    private func cancel() {
        appState.clearError()
        onDismiss()
    }

    private func createService() {
        guard isInputValid, !isCreating else { return }
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
