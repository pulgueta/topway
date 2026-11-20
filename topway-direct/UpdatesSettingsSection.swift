import SwiftUI

/// The Updates setting of the direct build. The App Store build does not have this section,
/// because the App Store updates that build.
struct UpdatesSettingsSection: View {
    @Environment(AppUpdater.self) private var appUpdater

    var body: some View {
        @Bindable var appUpdater = appUpdater

        Section {
            Toggle(
                "Check for updates automatically",
                isOn: $appUpdater.automaticallyChecksForUpdates
            )
            .disabled(!appUpdater.isAvailable)

            // Sparkle downloads updates in the background only while it checks automatically.
            Toggle(
                "Download and install updates automatically",
                isOn: $appUpdater.automaticallyDownloadsUpdates
            )
            .disabled(!appUpdater.isAvailable || !appUpdater.automaticallyChecksForUpdates)

            // Not available in a build with no update key, or while Sparkle downloads data in
            // the background.
            Button("Check for updates…") { appUpdater.checkForUpdates() }
                .disabled(!appUpdater.canCheckForUpdates)
                .help("Check for a new version of Topway now.")
        } header: {
            Text("Updates")
        } footer: {
            Text(
                appUpdater.isAvailable
                    ? "Topway checks for new versions at topway.pulgueta.com. It downloads the updates from GitHub."
                    : "This build has no update key, so it cannot check for updates."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
