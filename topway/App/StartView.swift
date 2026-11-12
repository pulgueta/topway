import SwiftUI

/// The start screen. It shows when Topway has no sign-in. A build with no OAuth client ID
/// offers only sample data.
struct StartView: View {
    @Environment(AppState.self) private var appState
    /// `false` while the window is closed. A closed window must not speak.
    @Environment(\.appearsActive) private var appearsActive

    var body: some View {
        // The sign-in window takes the focus, so the menu bar window can close. When it
        // opens again, VoiceOver says the result.
        let announcement = appState.signInError ?? appState.sessionNotice

        ContentUnavailableView {
            Label("Connect Topway to Railway", systemImage: "key")
        } description: {
            VStack(spacing: Layout.controlSpacing) {
                Text(description)
                if let error = appState.signInError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        } actions: {
            if appState.canSignIn {
                SignInButton(
                    title: appState.signInError == nil ? "Sign in with Railway" : "Try again"
                )
                .buttonStyle(.glassProminent)

                sampleDataButton
                    .buttonStyle(.bordered)
            } else {
                sampleDataButton
                    .buttonStyle(.glassProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: appearsActive ? announcement : nil) {
            guard appearsActive, let announcement else { return }
            AccessibilityNotification.Announcement(announcement).post()
        }
    }

    private var description: String {
        if !appState.canSignIn {
            "This build has no Railway OAuth client ID, so it cannot sign in. You can use Topway with sample data."
        } else if appState.isSigningIn {
            "Complete the sign-in in the browser window."
        } else if let notice = appState.sessionNotice {
            notice
        } else {
            "Sign in with your Railway account, and select the workspaces that Topway can use. Topway keeps the sign-in in the Keychain of this Mac."
        }
    }

    private var sampleDataButton: some View {
        Button("Try with sample data") {
            appState.enterSampleMode()
        }
        .help("Show sample projects. Topway does not connect to Railway.")
    }
}

#Preview {
    StartView()
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
