import SwiftUI
import TopwayCore

/// The picture of the last page: the right side of the menu bar with the Topway icon, and
/// below it a copy of the start screen of the menu bar window. The picture is only
/// decoration. The page text gives the same information.
struct MenuBarHero: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            menuBar
            Spacer(minLength: 0)
        }
        .frame(width: WelcomeLayout.textWidth)
        .foregroundStyle(.white)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var menuBar: some View {
        HStack(spacing: 14) {
            topwayIcon
            Image(systemName: "wifi")
            Image(systemName: "battery.100percent")
            Image(systemName: "switch.2")
            Text(verbatim: "9:41")
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 14)
        .frame(width: WelcomeLayout.textWidth, height: 28, alignment: .trailing)
        .background {
            // The bar fades out on the leading side, as the left part of the menu bar.
            WelcomeSurface(cornerRadius: 9)
                .mask {
                    LinearGradient(
                        colors: [.clear, .black], startPoint: .leading,
                        endPoint: UnitPoint(x: 0.45, y: 0.5))
                }
        }
    }

    /// The real menu bar icon, selected, with the pointer on it and the window below it.
    private var topwayIcon: some View {
        MenuBarLabel(health: HealthSummary(projects: []))
            .labelStyle(.iconOnly)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.white.opacity(0.28), in: .capsule)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "cursorarrow")
                    .font(.system(size: 15))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .offset(x: 9, y: 13)
            }
            .overlay(alignment: .top) {
                startWindow
                    .fixedSize()
                    .offset(y: 34)
            }
    }

    private var startWindow: some View {
        VStack(spacing: 8) {
            Label("Connect Topway to Railway", systemImage: "key")
                .font(.system(size: 11, weight: .semibold))
            pictureButton("Sign in with Railway", fill: WelcomePalette.accent)
            pictureButton("Try with sample data", fill: .white.opacity(0.16))
        }
        .padding(12)
        .frame(width: 196)
        .background { WelcomeSurface(cornerRadius: 14, isOpaque: true) }
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
    }

    /// A button in the picture. It looks like a button, but it is not a control.
    private func pictureButton(_ title: LocalizedStringKey, fill: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(fill, in: .capsule)
    }
}
