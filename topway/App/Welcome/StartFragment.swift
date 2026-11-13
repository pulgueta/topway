import SwiftUI
import TopwayCore

/// The copy for the last page: the menu bar with the selected Topway icon, and below it the
/// start screen of the menu bar window. `StartView` reads `AppState`, so this copy has the
/// same parts and texts. When you change `StartView`, change this copy too.
struct StartFragment: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MenuBarStrip(health: HealthSummary(projects: []), isSelected: true)

            FragmentWindow {
                ScreenLayout {
                    ContentUnavailableView {
                        Label("Connect Topway to Railway", systemImage: "key")
                    } description: {
                        Text(
                            "Sign in with your Railway account, and select the workspaces that Topway can use. Topway keeps the sign-in in the Keychain of this Mac."
                        )
                    } actions: {
                        Button("Sign in with Railway") {}
                            .buttonStyle(.glassProminent)
                        Button("Try with sample data") {}
                            .buttonStyle(.bordered)
                    }
                } top: {
                    FragmentProjectsHeader(showsRefresh: false)
                } bottom: {
                    // The stage cuts this bar. It keeps the start screen at its true position.
                    ActionBar {
                        EmptyView()
                    } actions: {
                        Button("Quit Topway") {}
                            .buttonStyle(.glass)
                    }
                }
            }
        }
    }
}
