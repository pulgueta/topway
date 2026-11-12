import SwiftUI

/// The settings, in the native `Settings` scene (⌘,). All settings apply at once.
struct SettingsView: View {
    @Environment(AppState.self) private var appState

    private let refreshIntervals: [(label: String, seconds: TimeInterval)] = [
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
    ]

    var body: some View {
        @Bindable var appState = appState

        Form {
            AccountSettingsSection()

            Section("Auto Refresh") {
                Toggle("Refresh automatically", isOn: $appState.autoRefreshEnabled)

                if appState.autoRefreshEnabled {
                    Picker("Refresh every", selection: $appState.autoRefreshInterval) {
                        ForEach(refreshIntervals, id: \.seconds) { interval in
                            Text(interval.label).tag(interval.seconds)
                        }
                    }
                }
            }

            AlertsSettingsSection()

            Section("General") {
                LaunchAtLoginToggle()
            }

            HelpSettingsSection()
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 640)
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
