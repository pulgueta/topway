import SwiftUI

struct AddServiceView: View {
    @Environment(AppState.self) private var appState

    let projectId: String
    let projectName: String
    let onDismiss: () -> Void

    @State private var sourceType: ServiceSourceType = .gitHub
    @State private var repoName: String = ""
    @State private var imageName: String = ""
    @State private var isCreating = false

    private var sourceValue: String {
        sourceType == .gitHub ? repoName : imageName
    }

    private var isInputValid: Bool {
        !sourceValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                BackButton { onDismiss() }

                Spacer()

                Text("Add Service")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Project Info
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                        Text(projectName)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.03))
                    )

                    // Source Type Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source Type")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            SourceTypeButton(
                                label: "GitHub",
                                icon: "link",
                                isSelected: sourceType == .gitHub
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    sourceType = .gitHub
                                }
                            }

                            SourceTypeButton(
                                label: "Docker",
                                icon: "shippingbox.fill",
                                isSelected: sourceType == .docker
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    sourceType = .docker
                                }
                            }
                        }
                    }

                    // Input Field based on source type
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sourceType == .gitHub ? "GitHub Repository" : "Docker Image")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)

                        TextField(
                            sourceType == .gitHub ? "owner/repository" : "image:tag",
                            text: sourceType == .gitHub ? $repoName : $imageName
                        )
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.04))
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )

                        Text(
                            sourceType == .gitHub
                                ? "e.g., railwayapp-templates/django"
                                : "e.g., nginx:latest"
                        )
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    }
                }
                .padding(16)
            }

            if let error = appState.errorMessage {
                ErrorBanner(message: error) { appState.clearError() }
            }

            Divider()

            // Footer with Create Button
            VStack {
                Button {
                    createService()
                } label: {
                    if isCreating {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Service")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(!isInputValid || isCreating)
            }
            .padding(16)
        }
    }

    private func createService() {
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
        .frame(width: 320, height: 400)
}
