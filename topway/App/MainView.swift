import SwiftUI
import TopwayCore

/// The root of the menu bar window. It holds the navigation, the sample data banner and
/// the confirmation dialog. `DESIGN.md` gives the layout rules.
struct MainView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var destination: NavigationDestination = .main

    var body: some View {
        VStack(spacing: 0) {
            // On every screen, so no sample item looks like a Railway item.
            if appState.isSampleMode {
                SampleDataBanner { appState.exitSampleMode() }
            }

            // No animation, so the banner needs no Reduce Motion rule.
            if let incident = appState.visibleIncident {
                IncidentBanner(incident: incident) { appState.hideIncident() }
            }

            ZStack {
                switch destination {
                case .main:
                    ProjectsScreen(
                        onAddService: { project in
                            show(.addService(projectId: project.id, projectName: project.name))
                        },
                        onOpenService: { service, project in
                            show(.service(service: service, project: project))
                        },
                        onOpenUsage: {
                            appState.clearError()
                            show(.usage)
                        }
                    )
                    .transition(.opacity)
                case .usage:
                    SpendView(
                        onDismiss: {
                            appState.clearError()
                            show(.main)
                        }
                    )
                    .transition(.screen(reduceMotion: reduceMotion))
                case .addService(let projectId, let projectName):
                    AddServiceView(
                        projectId: projectId,
                        projectName: projectName,
                        onDismiss: { show(.main) }
                    )
                    .transition(.screen(reduceMotion: reduceMotion))
                case .service(let service, let project):
                    ServiceView(
                        service: service,
                        project: project,
                        onDismiss: {
                            appState.clearError()
                            show(.main)
                        },
                        onDeleteService: {
                            if await appState.deleteService(serviceId: service.id) {
                                show(.main)
                            }
                        }
                    )
                    .transition(.screen(reduceMotion: reduceMotion))
                }
            }
        }
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
        .destructiveConfirmation(
            request: appState.pendingConfirmation,
            isLoading: appState.isRunningConfirmation,
            reduceMotion: reduceMotion,
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
            destination = .main
        }
        // With no token, only the start screen is correct.
        .onChange(of: appState.isConfigured) { _, isConfigured in
            if !isConfigured {
                destination = .main
            }
        }
        // Settings saved a different workspace or token. The open screen and a pending
        // confirmation belong to the earlier one.
        .onChange(of: appState.workspaceId) {
            appState.cancelConfirmation()
            destination = .main
        }
        .onChange(of: appState.railwayToken) {
            appState.cancelConfirmation()
            destination = .main
        }
        // Escape goes back one step.
        .onExitCommand {
            if appState.pendingConfirmation != nil {
                appState.cancelConfirmation()
            } else if destination != .main {
                appState.clearError()
                show(.main)
            }
        }
    }

    private func show(_ newDestination: NavigationDestination) {
        withAnimation(.screenChange) {
            destination = newDestination
        }
    }
}

#Preview {
    MainView()
        .environment(AppState())
}
