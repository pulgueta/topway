import SwiftUI

/// Gear button that opens the app's native `Settings` scene from the menu-bar
/// popover.
@MainActor
struct SettingsButton: View {
    @Environment(\.openSettings) private var openSettings
    @State private var isHovered = false

    var body: some View {
        Button {
            openAppSettings(fallback: openSettings)
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
                )
                .contentShape(.rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help("Settings")
        .accessibilityLabel("Settings")
    }
}

/// Opens the native `Settings` scene from a menu-bar context, matching the
/// behavior of the ⌘, menu item exactly.
///
/// `MenuBarExtra(.window)` hosts its content in a non-activating `NSPanel`.
/// Invoked from there, both `SettingsLink` and the `openSettings` environment
/// action silently no-op — they require a regular window context that the panel
/// doesn't provide (a known macOS 14–26 limitation). The Settings scene does
/// install a standard "Settings…" app-menu item bound to ⌘, though, so we
/// activate the app and send that item's own action: the button and ⌘, then go
/// through the identical, working code path. `openSettings` remains as a
/// forward-compatible fallback should the menu item ever go away.
@MainActor
func openAppSettings(fallback openSettings: OpenSettingsAction) {
    NSApp.activate()

    let settingsItem = NSApp.mainMenu?.items
        .lazy
        .compactMap(\.submenu)
        .flatMap(\.items)
        .first { $0.keyEquivalent == "," && $0.keyEquivalentModifierMask == .command }

    if let settingsItem, let action = settingsItem.action {
        NSApp.sendAction(action, to: settingsItem.target, from: settingsItem)
    } else {
        openSettings()
    }
}
