import SwiftUI
import TopwayCore

/// The Variables tab of the service screen: the list, its states and its actions.
/// `ServiceView` owns the variables and loads them.
struct VariablesTab: View {
    @Environment(AppState.self) private var appState

    let variables: [EnvironmentVariable]
    let isLoading: Bool
    /// `false` after a load that failed. An empty list is then not a fact.
    let areVariablesKnown: Bool
    let onRetry: () -> Void
    let onAdd: () -> Void
    let onEdit: (EnvironmentVariable) -> Void

    private var variableCount: String {
        "\(variables.count) variable\(variables.count == 1 ? "" : "s")"
    }

    var body: some View {
        ScreenLayout {
            content
        } top: {
            EmptyView()
        } bottom: {
            // With a known list, the error belongs to a different action, not to this load.
            if let error = appState.errorMessage, !variables.isEmpty || areVariablesKnown {
                ErrorBanner(message: error) { appState.clearError() }
            }

            ActionBar {
                if !isLoading || !variables.isEmpty {
                    Text(variableCount)
                }
            } actions: {
                if !variables.isEmpty {
                    CopyButton(title: "Copy all") { copyAll() }
                        .buttonStyle(.glass)
                        .help("Copy all variables as NAME=value lines.")
                }

                Button("Add variable", systemImage: "plus") { onAdd() }
                    .buttonStyle(.glassProminent)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !variables.isEmpty {
            // The list stays while a reload runs, so the screen does not flash.
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(variables) { variable in
                        VariableRow(variable: variable) { onEdit(variable) }
                    }
                }
            }
        } else if isLoading {
            LoadingStateView(title: "Loading variables…")
        } else if !areVariablesKnown {
            // The error can be gone, for example after a new token, but the list did not load.
            ErrorStateView(
                title: "Variables did not load",
                message: appState.errorMessage ?? "Select Try again to load the variables."
            ) { onRetry() }
        } else {
            ContentUnavailableView(
                "No variables",
                systemImage: "key",
                description: Text(
                    "This service has no variables in this environment. Select Add variable to make one."
                )
            )
        }
    }

    private func copyAll() {
        let lines = variables.map(\.dotenvLine)
        NSPasteboard.general.setSecret(lines.joined(separator: "\n"))
    }
}
