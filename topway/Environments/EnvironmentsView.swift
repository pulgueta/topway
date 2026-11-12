import SwiftUI
import TopwayCore

/// The environments of one project: the list, **New environment** and **Delete…**.
/// The list comes from `appState.projects`, so it shows each change after the reload.
struct EnvironmentsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let projectId: String
    /// The name stays on the screen while the projects load again.
    let projectName: String
    let onDismiss: () -> Void

    @State private var isAddingEnvironment = false

    private var environments: [RailwayEnvironment] {
        appState.projects.first { $0.id == projectId }?.environmentList ?? []
    }

    private var environmentCount: String {
        "\(environments.count) environment\(environments.count == 1 ? "" : "s")"
    }

    var body: some View {
        ZStack {
            if isAddingEnvironment {
                NewEnvironmentView(
                    projectId: projectId,
                    projectName: projectName,
                    environments: environments,
                    onDismiss: { showForm(false) }
                )
                .transition(.screen(reduceMotion: reduceMotion))
            } else {
                list
                    .transition(.opacity)
            }
        }
    }

    // MARK: - List

    private var list: some View {
        ScreenLayout {
            content
        } top: {
            ScreenHeader(title: "Environments", backTitle: "Projects", onBack: { onDismiss() })

            Label(projectName, systemImage: "folder")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Layout.barPadding)
                .padding(.bottom, Layout.controlSpacing)
                .accessibilityLabel("Project: \(projectName)")
        } bottom: {
            if let error = appState.errorMessage {
                ErrorBanner(message: error) { appState.clearError() }
            }

            ActionBar {
                Text(environmentCount)
            } actions: {
                Button("New environment", systemImage: "plus") { showForm(true) }
                    .buttonStyle(.glassProminent)
                    .help("Add an environment to \(projectName).")
            }
        }
        // Escape goes back one step.
        .onExitCommand {
            if appState.pendingConfirmation != nil {
                appState.cancelConfirmation()
            } else {
                onDismiss()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if environments.isEmpty {
            ContentUnavailableView(
                "No environments",
                systemImage: "square.stack.3d.up",
                description: Text(
                    "This project has no environments. Select New environment to make one.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(environments) { environment in
                        EnvironmentRow(environment: environment) { confirmDelete(of: environment) }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func showForm(_ isVisible: Bool) {
        appState.clearError()
        withAnimation(.screenChange) {
            isAddingEnvironment = isVisible
        }
    }

    private func confirmDelete(of environment: RailwayEnvironment) {
        appState.confirm(
            ConfirmationRequest(
                harm: .high,
                title: "Delete \(environment.name) from \(projectName)?",
                message:
                    "This removes the deployments, the variables and the data of all services "
                    + "in this environment. You cannot undo this.",
                actionTitle: "Delete environment",
                isDestructive: true,
                targetName: environment.name,
                environmentName: environment.name,
                perform: { _ = await appState.deleteEnvironment(environmentId: environment.id) }
            ))
    }
}

#Preview {
    EnvironmentsView(projectId: "1", projectName: "My Project", onDismiss: {})
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
