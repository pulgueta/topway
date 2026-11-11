import SwiftUI
import UserNotifications

/// The Alerts setting. Topway asks for notification permission only when the user turns it on.
struct AlertsSettingsSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    /// `nil` until Topway reads the permission.
    @State private var permission: UNAuthorizationStatus?
    @State private var permissionError: String?

    var body: some View {
        @Bindable var appState = appState

        Section {
            Toggle("Send alerts", isOn: $appState.alertsEnabled)

            if appState.alertsEnabled && permission == .denied {
                Label(
                    "Notifications for Topway are off in System Settings.",
                    systemImage: "bell.slash"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                Button("Open System Settings") { openNotificationSettings() }
                    .help("Turn on notifications for Topway.")
            }

            if let permissionError {
                Label(permissionError, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Alerts")
        } footer: {
            Text(
                "Get a notification when a deployment fails, a service crashes or a service recovers. Topway checks at each refresh. To mute a project, select Manage in its row, then Mute alerts."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .task {
            await readPermission()
        }
        .onChange(of: appState.alertsEnabled) { _, isOn in
            guard isOn else { return }
            Task { await requestPermission() }
        }
        // The user can change the permission in System Settings while this window is open.
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            Task { await readPermission() }
        }
    }

    private func readPermission() async {
        permission = await UNUserNotificationCenter.current().notificationSettings()
            .authorizationStatus
    }

    /// Shows the system prompt the first time. Later requests give the saved answer.
    private func requestPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [
                .alert, .sound,
            ])
            permissionError = nil
        } catch {
            permissionError =
                "Topway cannot ask for notification permission. \(error.localizedDescription)"
        }
        await readPermission()
    }

    private func openNotificationSettings() {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        if let url = URL(
            string:
                "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleId)"
        ) {
            openURL(url)
        }
    }
}
