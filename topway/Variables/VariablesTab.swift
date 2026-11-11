import SwiftUI
import TopwayCore

/// The Variables tab of the service screen: the list, its states and its actions.
/// `ServiceView` owns the variables and loads them.
struct VariablesTab: View {
    @Environment(AppState.self) private var appState

    let variables: [EnvironmentVariable]
    let isLoading: Bool
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
            if let error = appState.errorMessage, !variables.isEmpty {
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
        } else if let error = appState.errorMessage {
            ErrorStateView(title: "Variables did not load", message: error) { onRetry() }
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
        let lines = variables.map { "\($0.name)=\($0.value)" }
        NSPasteboard.general.setSecret(lines.joined(separator: "\n"))
    }
}
