import SwiftUI
import TopwayCore

/// The Account setting: the signed-in user, the workspace and **Sign out…**. The sign-out
/// confirmation stays in this window. A separate dialog is not necessary.
struct AccountSettingsSection: View {
    @Environment(AppState.self) private var appState
    /// `false` while the window is not active. An inactive window must not speak.
    @Environment(\.appearsActive) private var appearsActive

    @State private var loadError: String?
    @State private var isConfirmingSignOut = false
    @State private var signOutError: String?

    var body: some View {
        Section {
            if appState.isSignedIn {
                signedInRows
            } else if appState.canSignIn {
                signedOutRows
            } else {
                Text("This build has no Railway OAuth client ID, so it cannot sign in.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Account")
        } footer: {
            Text(
                "Topway keeps the sign-in in the Keychain of this Mac. Sign out removes it from this Mac. To remove the access of Topway on Railway, open your Railway account settings and select Apps."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Sample mode loads no account, so the load runs again when sample mode ends.
        .task(id: [appState.isSignedIn, appState.isSampleMode]) {
            guard appState.isSignedIn, !appState.isSampleMode, appState.account == nil else {
                return
            }
            loadError = await appState.loadAccount()
        }
        // The error replaces the loading row, so VoiceOver must say it, also after a failed
        // Try again, but only while this window is active.
        .task(id: appearsActive ? loadError : nil) {
            guard appearsActive, let loadError else { return }
            AccessibilityNotification.Announcement("Error: \(loadError)").post()
        }
        // The sign-in window takes the focus, so VoiceOver says the error when this window is
        // active again.
        .task(id: appearsActive ? appState.signInError : nil) {
            guard appearsActive, let error = appState.signInError else { return }
            AccessibilityNotification.Announcement(error).post()
        }
    }

    // MARK: - Signed Out

    /// After a failed sign-in, the message shows in red with a symbol, and the button is
    /// **Try again**.
    @ViewBuilder
    private var signedOutRows: some View {
        LabeledContent {
            SignInButton(title: appState.signInError == nil ? "Sign in with Railway" : "Try again")
                .buttonStyle(.glassProminent)
        } label: {
            Text("You are not signed in.")
                .foregroundStyle(.secondary)
        }

        if let error = appState.signInError {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    // MARK: - Signed In

    @ViewBuilder
    private var signedInRows: some View {
        LabeledContent("Signed in as") {
            if let account = appState.account {
                Text(account.name.map { "\($0) (\(account.email))" } ?? account.email)
                    .textSelection(.enabled)
            } else if appState.isSampleMode {
                Text("Exit sample data to see the account.")
                    .foregroundStyle(.secondary)
            } else if loadError == nil {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Loading the account")
            }
        }

        if let loadError {
            LabeledContent {
                Button("Try again") {
                    Task { self.loadError = await appState.loadAccount() }
                }
            } label: {
                Label(loadError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }

        if let workspaces = appState.account?.workspaces, !workspaces.isEmpty {
            Picker(
                "Workspace",
                selection: Binding(
                    get: { appState.workspaceId },
                    set: { appState.selectWorkspace($0) })
            ) {
                if appState.workspaceId.isEmpty {
                    Text("Choose a workspace").tag("")
                }
                ForEach(workspaces) { workspace in
                    Text(workspace.name).tag(workspace.id)
                }
            }
            .help("Select the workspace of the projects list.")
        }

        signOutRows
    }

    // MARK: - Sign Out

    @ViewBuilder
    private var signOutRows: some View {
        if isConfirmingSignOut {
            LabeledContent {
                Button("Cancel") { isConfirmingSignOut = false }
                Button("Sign out", role: .destructive) { signOut() }
                    .foregroundStyle(.red)
            } label: {
                Text("Sign out of Railway on this Mac?")
                Text(
                    appState.isSampleMode
                        ? "The sample data stays. When you exit it, Topway shows the start screen. To connect again, sign in."
                        : "Topway then shows the start screen. To connect again, sign in."
                )
            }
        } else {
            LabeledContent {
                Button("Sign out…", role: .destructive) { isConfirmingSignOut = true }
                    .foregroundStyle(.red)
                    .help("Remove the sign-in from the Keychain of this Mac.")
            } label: {
                Text("Sign out removes the sign-in from this Mac.")
                    .foregroundStyle(.secondary)
            }
        }

        if let signOutError {
            Label(signOutError, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    private func signOut() {
        isConfirmingSignOut = false
        if appState.signOut() {
            signOutError = nil
            loadError = nil
        } else {
            signOutError = "Topway cannot remove the sign-in from the Keychain. Try again."
        }
    }
}
