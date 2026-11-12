import SwiftUI

/// The settings, in the native `Settings` scene (⌘,).
/// The credentials need Save. All other settings apply at once.
struct SettingsView: View {
    @Environment(AppState.self) private var appState

    // Topway writes the token to the Keychain only on Save, not on each key press.
    @State private var token = ""
    @State private var workspace = ""
    @State private var hasLoaded = false
    @State private var isSaved = false
    @State private var saveError: String?
    @State private var isConfirmingRemoval = false
    @State private var removalError: String?

    private let refreshIntervals: [(label: String, seconds: TimeInterval)] = [
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
    ]

    private let tokensURL = URL(string: "https://railway.com/account/tokens")

    var body: some View {
        @Bindable var appState = appState

        Form {
            Section {
                SecureField("API token", text: $token, prompt: Text("Paste your token"))
                TextField("Workspace ID", text: $workspace, prompt: Text("Paste your Workspace ID"))

                LabeledContent {
                    Button("Save") { save() }
                        .buttonStyle(.glassProminent)
                        .disabled(token.isEmpty || workspace.isEmpty)
                        .help("Save the token to the Keychain and load your projects.")
                } label: {
                    saveStatus
                }

                if !appState.railwayToken.isEmpty {
                    removeTokenRows
                }
            } header: {
                Text("Credentials")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        "Make a token in your Railway account settings. To find the Workspace ID, press ⌘K in Railway and select \u{201C}Copy Active Workspace ID\u{201D}. Topway keeps the token in the Keychain of this Mac."
                    )
                    if let tokensURL {
                        Link("Open the Railway tokens page", destination: tokensURL)
                            .foregroundStyle(.tint)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("Auto Refresh") {
                Toggle("Refresh automatically", isOn: $appState.autoRefreshEnabled)

                if appState.autoRefreshEnabled {
                    Picker("Refresh every", selection: $appState.autoRefreshInterval) {
                        ForEach(refreshIntervals, id: \.seconds) { interval in
                            Text(interval.label).tag(interval.seconds)
                        }
                    }
                }
            }

            AlertsSettingsSection()

            Section("General") {
                LaunchAtLoginToggle()
            }

            HelpSettingsSection()
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 640)
        .task {
            guard !hasLoaded else { return }
            token = appState.railwayToken
            workspace = appState.workspaceId
            hasLoaded = true
        }
        // "Saved" is true only for the text that is in the fields.
        .onChange(of: token) { isSaved = false }
        .onChange(of: workspace) { isSaved = false }
    }

    // MARK: - Save

    @ViewBuilder
    private var saveStatus: some View {
        if let saveError {
            Label(saveError, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        } else if isSaved {
            Label("Saved", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.secondary)
        } else {
            Text("Save applies the token and the Workspace ID.")
                .foregroundStyle(.secondary)
        }
    }

    private func save() {
        appState.workspaceId = workspace
        if appState.updateToken(token) {
            saveError = nil
            isSaved = true
            AccessibilityNotification.Announcement("Saved").post()
            // Saved credentials replace the sample data. Sample mode never saves a token.
            appState.exitSampleMode()
            appState.restartAutoRefresh()
            Task { await appState.loadProjects() }
        } else {
            isSaved = false
            let message = "Topway cannot save the token to the Keychain. Try again."
            saveError = message
            AccessibilityNotification.Announcement(message).post()
        }
    }

    // MARK: - Remove token

    /// The confirmation stays in this window. A separate dialog is not necessary.
    @ViewBuilder
    private var removeTokenRows: some View {
        if isConfirmingRemoval {
            LabeledContent {
                Button("Cancel") { isConfirmingRemoval = false }
                Button("Remove token", role: .destructive) { removeToken() }
                    .foregroundStyle(.red)
            } label: {
                Text("Remove the token from this Mac?")
                Text("Topway then shows the start screen. To connect again, add a token.")
            }
        } else {
            LabeledContent {
                Button("Remove token…", role: .destructive) { isConfirmingRemoval = true }
                    .foregroundStyle(.red)
                    .help("Delete the saved token from the Keychain of this Mac.")
            } label: {
                Text("A token is saved on this Mac.")
                    .foregroundStyle(.secondary)
            }
        }

        if let removalError {
            Label(removalError, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    private func removeToken() {
        isConfirmingRemoval = false
        if appState.removeToken() {
            token = ""
            saveError = nil
            removalError = nil
        } else {
            removalError = "Topway cannot remove the token from the Keychain. Try again."
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
