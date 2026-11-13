import SwiftUI
import TopwayCore

/// Shows why a load failed and what the user can do next.
/// The actions come from `AppState.recoveryActions`, so a rejected token never traps the user.
struct ErrorStateView: View {
    @Environment(AppState.self) private var appState
    /// `false` while the window is closed. A closed window must not speak.
    @Environment(\.appearsActive) private var appearsActive

    /// Says what did not load, for example "Projects did not load".
    let title: String
    let message: String
    let onRetry: () -> Void

    var body: some View {
        let actions = appState.recoveryActions
        let shownTitle = appState.isTokenRejected ? "Railway did not accept your sign-in" : title
        let shownMessage =
            appState.isTokenRejected
            ? "The sign-in has no access to this workspace, or Railway ended it. Sign in again and select the workspace on the Railway page, or use sample data."
            : message

        // A failed Sign in again. It is `nil` when the token is not rejected.
        let signInFailure = appState.signInAgainError
        let announcement =
            "\(shownTitle). \(shownMessage)" + (signInFailure.map { " \($0)" } ?? "")

        ContentUnavailableView {
            Label(shownTitle, systemImage: "exclamationmark.triangle")
        } description: {
            VStack(spacing: Layout.controlSpacing) {
                Text(shownMessage)
                if let signInFailure {
                    Label(signInFailure, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        } actions: {
            ForEach(actions, id: \.self) { action in
                RecoveryButton(action: action, isPrimary: action == actions.first, onRetry: onRetry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The error replaces the content, so VoiceOver must say it, with the cause and the next
        // step, but only in an open window. When the window opens again, VoiceOver says it.
        .task(id: appearsActive ? announcement : nil) {
            guard appearsActive else { return }
            AccessibilityNotification.Announcement(announcement).post()
        }
    }
}
