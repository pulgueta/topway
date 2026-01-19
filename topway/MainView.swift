import SwiftUI

enum NavigationDestination: Equatable {
    case main
    case settings
    case addService(projectId: String, projectName: String)
    case variables(service: Service, project: Project)
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main), (.settings, .settings):
            return true
        case let (.addService(lhsId, lhsName), .addService(rhsId, rhsName)):
            return lhsId == rhsId && lhsName == rhsName
        case let (.variables(lhsService, lhsProject), .variables(rhsService, rhsProject)):
            return lhsService.id == rhsService.id && lhsProject.id == rhsProject.id
        default:
            return false
        }
    }
}

struct MainView: View {
    @Environment(AppState.self) private var appState
    @State private var currentView: NavigationDestination = .main
    
    var body: some View {
        ZStack {
            switch currentView {
            case .main:
                mainContent
                    .transition(.opacity)
            case .settings:
                SettingsView(onDismiss: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentView = .main 
                    }
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))
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
                VariablesView(
                    service: service,
                    project: project,
                    onDismiss: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentView = .main 
                        }
                    },
                    onDeleteService: {
                        _ = await appState.deleteService(serviceId: service.id)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentView = .main
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: 320, height: 400)
        .task {
            if appState.isConfigured && appState.projects.isEmpty {
                await appState.loadProjects()
            }
        }
        // Escape to go back
        .onExitCommand {
            switch currentView {
            case .main:
                break // Do nothing on main view
            case .settings, .addService, .variables:
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentView = .main
                }
            }
        }
        // Listen for settings toggle from menu command
        .onChange(of: appState.showingSettings) { _, newValue in
            if newValue && currentView == .main {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentView = .settings
                }
                appState.showingSettings = false
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
                errorView(error)
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
            
            ToolbarButton(icon: "gearshape", help: "Settings") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentView = .settings
                }
            }
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
            
            Button("Open Settings") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentView = .settings
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            
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
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            VStack(spacing: 4) {
                Text("Error")
                    .font(.system(size: 14, weight: .semibold))
                
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Button("Retry") {
                Task { await appState.loadProjects() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            
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
                
                ToolbarButton(icon: "plus", help: "Create project on Railway") {
                    openRailwayDashboard()
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
                                        currentView = .addService(projectId: project.id, projectName: project.name)
                                    }
                                },
                                onDeleteProject: {
                                    Task {
                                        await appState.deleteProject(projectId: project.id)
                                    }
                                },
                                onServiceTap: { service in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentView = .variables(service: service, project: project)
                                    }
                                }
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
                errorBanner(error)
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
                
                Text("Create a project on Railway or check your Workspace ID in settings.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            HStack(spacing: 10) {
                Button {
                    openRailwayDashboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("New Project")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentView = .settings
                    }
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
    
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.system(size: 11))
                .lineLimit(1)
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.clearError()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
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
    
    private func openRailwayDashboard() {
        if let url = URL(string: "https://railway.app/new") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Toolbar Button

struct ToolbarButton: View {
    let icon: String?
    var isLoading: Bool = false
    let help: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .frame(width: 24, height: 24)
            .foregroundStyle(isHovered ? .primary : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(help)
    }
}

#Preview {
    MainView()
        .environment(AppState())
}
