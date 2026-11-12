import SwiftUI
import TopwayCore

/// Shows after a sign-in when the user shared several workspaces. The user chooses the
/// workspace of the projects list. Settings can change it later.
struct WorkspacePickerView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        content
            .task {
                // The sign-in loads the account itself.
                guard appState.account == nil, !appState.isSigningIn else { return }
                await appState.loadAccount()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let account = appState.account {
            if account.workspaces.isEmpty {
                noWorkspaces
            } else {
                workspaceList(account.workspaces)
            }
        } else if let error = appState.errorMessage {
            ErrorStateView(title: "Workspaces did not load", message: error) {
                Task { await appState.loadAccount() }
            }
        } else {
            LoadingStateView(title: "Loading workspaces…")
        }
    }

    private func workspaceList(_ workspaces: [WorkspaceSummary]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose a workspace")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(
                    "Topway shows the projects of one workspace. To change it later, open Settings."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Layout.contentInset)
            .padding(.vertical, Layout.controlSpacing)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(workspaces) { workspace in
                        row(for: workspace)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func row(for workspace: WorkspaceSummary) -> some View {
        Button {
            appState.selectWorkspace(workspace.id)
        } label: {
            HStack(spacing: Layout.controlSpacing) {
                Image(systemName: "square.stack.3d.up")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(workspace.name)
                    .lineLimit(1)

                Spacer(minLength: Layout.controlSpacing)

                // Always visible, to show that the row opens the projects.
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(RowButtonStyle())
        .help("Show the projects of \(workspace.name).")
        .accessibilityLabel(workspace.name)
        .accessibilityHint("Shows the projects of this workspace.")
    }

    private var noWorkspaces: some View {
        ContentUnavailableView {
            Label("No shared workspaces", systemImage: "square.stack.3d.up.slash")
        } description: {
            VStack(spacing: Layout.controlSpacing) {
                Text(
                    "You did not share a workspace with Topway. Sign in again, and select a workspace on the Railway page."
                )
                // A failed sign-in from this screen.
                if let error = appState.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        } actions: {
            SignInButton(title: "Sign in again")
                .buttonStyle(.glassProminent)
        }
    }
}

#Preview {
    WorkspacePickerView()
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
