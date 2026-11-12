import SwiftUI

/// Starts Sign in with Railway. The button is not available while the sign-in window is open.
/// The caller sets the button style.
struct SignInButton: View {
    @Environment(AppState.self) private var appState

    var title = "Sign in with Railway"

    var body: some View {
        Button(title) {
            Task { await appState.signIn() }
        }
        .disabled(appState.isSigningIn)
        .help("Open the Railway sign-in page in a browser window.")
    }
}
