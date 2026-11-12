import SwiftUI

/// The start screen. It shows when Topway has no token or no Workspace ID.
struct StartView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        ContentUnavailableView {
            Label("Connect Topway to Railway", systemImage: "key")
        } description: {
            Text(
                "Add your Railway API token and Workspace ID in Settings. Topway keeps the token in the Keychain of this Mac."
            )
        } actions: {
            Button("Open Settings") {
                openAppSettings(fallback: openSettings)
            }
            .buttonStyle(.glassProminent)

            Button("Try with sample data") {
                appState.enterSampleMode()
            }
            .buttonStyle(.bordered)
            .help("Show sample projects. Topway does not connect to Railway.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    StartView()
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
