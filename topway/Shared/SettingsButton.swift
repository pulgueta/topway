import SwiftUI

/// Opens the native `Settings` scene from the menu bar window.
struct SettingsButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings", systemImage: "gearshape") {
            openAppSettings(fallback: openSettings)
        }
        .buttonStyle(.glass)
        .help("Open the Topway settings (⌘,)")
    }
}
