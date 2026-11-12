import SwiftUI
import TopwayCore

/// Shows why a load failed and what the user can do next.
/// The actions come from `AppState.recoveryActions`, so a rejected token never traps the user.
struct ErrorStateView: View {
    @Environment(AppState.self) private var appState

    /// Says what did not load, for example "Projects did not load".
    let title: String
    let message: String
    let onRetry: () -> Void

    var body: some View {
        let actions = appState.recoveryActions

        ContentUnavailableView {
            Label(
                appState.isTokenRejected ? "Railway did not accept your token" : title,
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(
                appState.isTokenRejected
                    ? "The token is expired or not correct, or it has no access to this workspace. Check the token and the Workspace ID in Settings, or use sample data."
                    : message
            )
        } actions: {
            ForEach(actions, id: \.self) { action in
                RecoveryButton(action: action, isPrimary: action == actions.first, onRetry: onRetry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
