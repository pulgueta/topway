import SwiftUI

/// The top bar of the projects screen: the app name, Refresh and Settings.
struct ProjectsHeader: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        GlassEffectContainer(spacing: Layout.controlSpacing) {
            HStack(spacing: Layout.controlSpacing) {
                Label {
                    Text("Topway")
                } icon: {
                    Image(systemName: "tram.fill")
                        .foregroundStyle(.tint)
                }
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

                if appState.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Loading projects")
                }

                Spacer(minLength: Layout.controlSpacing)

                if appState.isConfigured {
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        Task { await appState.loadProjects() }
                    }
                    .buttonStyle(.glass)
                    .disabled(appState.isLoading)
                    .help("Load the projects again (⌘R)")
                }

                SettingsButton()
            }
        }
        .padding(.horizontal, Layout.barPadding)
        .padding(.vertical, 10)
    }
}

#Preview {
    ProjectsHeader()
        .environment(AppState())
        .frame(width: Layout.windowWidth)
}
