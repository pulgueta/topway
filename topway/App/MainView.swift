import SwiftUI
import TopwayCore

@MainActor
struct MainView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @Environment(\.openSettings) private var openSettings
    @State private var currentView: NavigationDestination = .main

    var body: some View {
        VStack(spacing: 0) {
            // On every screen, so no sample item looks like a Railway item.
            if appState.isSampleMode {
                SampleDataBanner { appState.exitSampleMode() }
                Divider()
            }
            ZStack {
                switch currentView {
                case .main:
                    mainContent
                        .transition(.opacity)
                case .addService(let projectId, let projectName):
                    AddServiceView(
                        projectId: projectId,
                        projectName: projectName,
                        onDismiss: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentView = .main
                            }
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                case .variables(let service, let project):
                    ServiceView(
                        service: service,
                        project: project,
                        onDismiss: {
                            appState.clearError()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentView = .main
                            }
                        },
                        onDeleteService: {
                            if await appState.deleteService(serviceId: service.id) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentView = .main
                                }
                            }
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
        .destructiveConfirmation(
            request: appState.pendingConfirmation,
            isLoading: appState.isRunningConfirmation,
            onConfirm: { appState.runPendingConfirmation() },
            onCancel: { appState.cancelConfirmation() }
        )
        // Runs again when sample mode starts or ends, to load the projects of the new source.
        .task(id: appState.isSampleMode) {
            if appState.isConfigured && appState.projects.isEmpty {
                await appState.loadProjects()
            }
        }
        // Screens of the earlier data source show items that the new source does not have.
        .onChange(of: appState.isSampleMode) {
            currentView = .main
        }
        // With no token, only the start screen is correct.
        .onChange(of: appState.isConfigured) { _, isConfigured in
            if !isConfigured {
                currentView = .main
            }
        }
        // Escape to go back
        .onExitCommand {
            if appState.pendingConfirmation != nil {
                appState.cancelConfirmation()
                return
            }

            switch currentView {
            case .main:
                break  // Do nothing on main view
            case .addService, .variables:
                appState.clearError()
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentView = .main
                }
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            if !appState.isConfigured {
                unconfiguredView
            } else if appState.isLoading && appState.projects.isEmpty {
                loadingView
            } else if let error = appState.errorMessage, appState.projects.isEmpty {
                ErrorStateView(title: "Projects did not load", message: error) {
                    Task { await appState.loadProjects() }
                }
            } else {
                projectsListView
            }

            Divider()
            footerView
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "tram.fill")
                .font(.system(size: 14))
                .foregroundStyle(.purple)

            Text("Topway")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            SettingsButton()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Unconfigured View

    private var unconfiguredView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("Not Configured")
                    .font(.system(size: 14, weight: .semibold))

                Text("Add your Railway API token and Workspace ID to get started.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 8) {
                Button("Open Settings") {
                    openAppSettings(fallback: openSettings)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.regular)

                Button("Try with sample data") {
                    appState.enterSampleMode()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .help("Show sample projects. Topway does not connect to Railway.")
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .controlSize(.regular)
            Text("Loading projects...")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Projects List View

    private var projectsListView: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("Projects")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if !appState.isSampleMode {
                    ToolbarButton(icon: "plus", help: "Create project on Railway") {
                        openRailwayDashboard()
                    }
                }

                ToolbarButton(
                    icon: appState.isLoading ? nil : "arrow.clockwise",
                    isLoading: appState.isLoading,
                    help: "Refresh"
                ) {
                    Task { await appState.loadProjects() }
                }
                .disabled(appState.isLoading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if appState.projects.isEmpty {
                emptyProjectsView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(appState.projects) { project in
                            ProjectRow(
                                project: project,
                                onAddService: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentView = .addService(
                                            projectId: project.id, projectName: project.name)
                                    }
                                },
                                onRequestDelete: {
                                    confirmDelete(of: project)
                                },
                                onServiceTap: { service in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentView = .variables(service: service, project: project)
                                    }
                                },
                                isMuted: appState.mutedProjectIds.contains(project.id),
                                onToggleMute: appState.alertsEnabled
                                    ? { appState.toggleMute(projectId: project.id) } : nil
                            )
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .clipped()
            }

            // Error Banner
            if let error = appState.errorMessage, !appState.projects.isEmpty {
                ErrorBanner(message: error) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.clearError()
                    }
                }
            }
        }
    }

    private var emptyProjectsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("No Projects Found")
                    .font(.system(size: 14, weight: .semibold))

                Text(
                    appState.isSampleMode
                        ? "You deleted all sample projects. To get them back, exit sample data and start it again."
                        : "Create a project on Railway or check your Workspace ID in settings."
                )
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }

            HStack(spacing: 10) {
                if !appState.isSampleMode {
                    Button {
                        openRailwayDashboard()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10))
                            Text("Create project")
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
                }

                Button {
                    openAppSettings(fallback: openSettings)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10))
                        Text("Settings")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Text("\(appState.projects.count) project\(appState.projects.count == 1 ? "" : "s")")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

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
    MainView()
        .environment(AppState())
}
