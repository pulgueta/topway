import SwiftUI

/// A copy of `ProjectsHeader` for the copies of the app in the welcome window.
/// `ProjectsHeader` reads `AppState`, and the welcome window must not make one, because
/// `AppState.init` changes the Keychain and `UserDefaults`. This copy has the same parts.
/// When you change `ProjectsHeader`, change this copy too.
struct FragmentProjectsHeader: View {
    /// `false` on the start screen, where the projects header shows no **Refresh**.
    let showsRefresh: Bool

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

                Spacer(minLength: Layout.controlSpacing)

                if showsRefresh {
                    Button("Refresh", systemImage: "arrow.clockwise") {}
                        .buttonStyle(.glass)
                }

                SettingsButton()
            }
        }
        .padding(.horizontal, Layout.barPadding)
        .padding(.vertical, 10)
    }
}
