import SwiftUI

/// Preferences pane, presented in the native `Settings` scene (⌘,).
struct SettingsView: View {
    @Environment(AppState.self) private var appState

    // Edited locally and applied on Save so we don't write the token to the
    // Keychain on every keystroke.
    @State private var token = ""
    @State private var workspace = ""
    @State private var hasLoaded = false
    @State private var saveError: String?

    private let refreshIntervals: [(label: String, seconds: TimeInterval)] = [
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
    ]

    var body: some View {
        @Bindable var appState = appState

        Form {
            Section {
                SecureField("Railway API token", text: $token)
                TextField("Workspace ID", text: $workspace)
            } header: {
                Text("Credentials")
            } footer: {
                Label(
                    "Find your Workspace ID by pressing ⌘K in Railway and selecting \u{201C}Copy Active Workspace ID\u{201D}.",
                    systemImage: "info.circle"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Auto Refresh") {
                Toggle("Enable auto-refresh", isOn: $appState.autoRefreshEnabled)

                if appState.autoRefreshEnabled {
                    Picker("Refresh every", selection: $appState.autoRefreshInterval) {
                        ForEach(refreshIntervals, id: \.seconds) { interval in
                            Text(interval.label).tag(interval.seconds)
                        }
                    }
                }
            }

            Section {
                Button("Save") {
                    appState.workspaceId = workspace
                    if appState.updateToken(token) {
                        saveError = nil
                        Task { await appState.loadProjects() }
                    } else {
                        saveError = "Couldn't save the token to the Keychain. Please try again."
                    }
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(token.isEmpty || workspace.isEmpty)

                if let saveError {
                    Label(saveError, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .scenePadding()
        .frame(width: 420, height: 360)
        .task {
            guard !hasLoaded else { return }
            token = appState.railwayToken
            workspace = appState.workspaceId
            hasLoaded = true
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
