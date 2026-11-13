import SwiftUI
import TopwayCore

/// The welcome window. It shows one time, at the first launch, and tells the user where
/// the menu bar icon is. Topway has no Dock icon, so without it the user can see nothing.
struct WelcomeView: View {
    /// The `UserDefaults` key that records that the welcome window showed.
    static let shownKey = "welcomeWindowShown"

    @AppStorage(WelcomeView.shownKey) private var isShown = false
    @Environment(\.dismissWindow) private var dismissWindow
    @ScaledMetric private var iconSize = 64.0

    var body: some View {
        VStack(spacing: Layout.barPadding) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)

            Text("Topway is in the menu bar")
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            Text(
                "Topway has no Dock icon and no window. Click the Topway icon at the top right of the screen to see your projects."
            )

            menuBarIcon

            Text(
                "If you cannot see the icon, the menu bar can be full. Quit some menu bar apps to make space, or turn on Topway in System Settings > Menu Bar."
            )
            .font(.callout)
            .foregroundStyle(.secondary)

            Button("OK") { dismissWindow() }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(.defaultAction)
                .help("Close this window.")
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .scenePadding()
        // The same width as the menu bar window. The height follows the text size.
        .frame(width: Layout.windowWidth)
        .onAppear {
            isShown = true
            // Topway is an accessory app, so the window can open behind other windows.
            NSApp.activate()
        }
    }

    /// The icon that the menu bar shows when all services are healthy. It uses
    /// `MenuBarLabel`, so it stays the same as the real icon.
    private var menuBarIcon: some View {
        VStack(spacing: Layout.controlSpacing) {
            Text("Look for this icon")
                .font(.callout)
            MenuBarLabel(health: HealthSummary(projects: []))
                .labelStyle(.iconOnly)
                .font(.title)
        }
        // VoiceOver reads "Look for this icon, Topway", the name of the menu bar item.
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WelcomeView()
}
