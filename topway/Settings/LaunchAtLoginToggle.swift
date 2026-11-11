import ServiceManagement
import SwiftUI

/// Shows the real login item state of Topway, and changes it through `SMAppService`.
struct LaunchAtLoginToggle: View {
    @State private var status = SMAppService.mainApp.status
    @State private var errorMessage: String?

    var body: some View {
        Group {
            // The system keeps the state, so the toggle reads it and does not keep a copy.
            Toggle(
                "Launch at login",
                isOn: Binding(
                    get: { status == .enabled || status == .requiresApproval },
                    // A closure, not the method reference: Xcode 26.6 crashes when it converts
                    // a main-actor method to the setter type.
                    set: { setLaunchAtLogin($0) })
            )

            if status == .requiresApproval {
                Label(
                    "Allow Topway in Login Items in System Settings.",
                    systemImage: "exclamationmark.circle"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                Button("Open Login Items") {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        // The user can change the login items in System Settings while this window is open.
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            status = SMAppService.mainApp.status
        }
    }

    private func setLaunchAtLogin(_ isOn: Bool) {
        do {
            if isOn {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage =
                isOn
                ? "Topway cannot turn on launch at login. \(error.localizedDescription)"
                : "Topway cannot turn off launch at login. \(error.localizedDescription)"
        }
        status = SMAppService.mainApp.status
        // `register()` can throw when macOS waits for the user's approval. The approval hint
        // explains that state, so an error message is not necessary.
        if status == .requiresApproval {
            errorMessage = nil
        }
    }
}
