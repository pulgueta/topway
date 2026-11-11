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
