import SwiftUI
import TopwayCore

/// The first screen: all projects and their services, or the start screen.
struct ProjectsScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @Environment(\.openSettings) private var openSettings

    let onAddService: (Project) -> Void
    let onOpenService: (Service, Project) -> Void

    private var projectCount: String {
        let count = appState.projects.count
        return "\(count) project\(count == 1 ? "" : "s")"
    }

    var body: some View {
        ScreenLayout {
            content
        } top: {
            ProjectsHeader()
        } bottom: {
            if let error = appState.errorMessage, !appState.projects.isEmpty {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if !appState.isConfigured {
            StartView()
        } else if !appState.projects.isEmpty {
            projectList
        } else if let error = appState.errorMessage {
            // The error stays while a background refresh runs, so the screen does not flash.
            ErrorStateView(title: "Projects did not load", message: error) {
                Task { await appState.loadProjects() }
            }
        } else if appState.isLoading {
            LoadingStateView(title: "Loading projects…")
        } else {
            emptyView
        }
    }

    private var projectList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(appState.projects) { project in
                    ProjectRow(
                        project: project,
                        isMuted: appState.mutedProjectIds.contains(project.id),
                        onAddService: { onAddService(project) },
                        onRequestDelete: { confirmDelete(of: project) },
                        onServiceTap: { service in onOpenService(service, project) },
                        onToggleMute: appState.alertsEnabled
                            ? { appState.toggleMute(projectId: project.id) } : nil
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No projects", systemImage: "folder")
        } description: {
            Text(
                appState.isSampleMode
                    ? "You deleted all sample projects. To get them back, exit sample data and start it again."
                    : "This workspace has no projects. Select New project to create one on Railway, or check the Workspace ID in Settings."
            )
        } actions: {
            if !appState.isSampleMode {
                Button("Open Settings") {
                    openAppSettings(fallback: openSettings)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        ActionBar {
            if !appState.projects.isEmpty {
                Text(projectCount)
            }
        } actions: {
            // Railway has no public API to create a project, so this opens the dashboard.
            if appState.isConfigured && !appState.isSampleMode {
                Button("New project", systemImage: "arrow.up.forward") {
                    openRailwayDashboard()
                }
                .buttonStyle(.glass)
                .help("Open Railway in your browser to create a project.")
            }

            Button("Quit Topway") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.glass)
        }
    }

    // MARK: - Actions

    private func confirmDelete(of project: Project) {
        appState.confirm(
            ConfirmationRequest(
                harm: .high,
                title: "Delete \(project.name)?",
                message:
                    "This removes all services, deployments and data in the project. "
                    + "You cannot undo this.",
                actionTitle: "Delete project",
                isDestructive: true,
                targetName: project.name,
                environmentName: project.productionEnvironmentName,
                perform: { _ = await appState.deleteProject(projectId: project.id) }
            ))
    }

    private func openRailwayDashboard() {
        if let url = URL(string: "https://railway.com/new") {
            openURL(url)
        }
    }
}

#Preview {
    ProjectsScreen(onAddService: { _ in }, onOpenService: { _, _ in })
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
