import SwiftUI
import TopwayCore

/// A copy of the right end of the menu bar: the real Topway icon (`MenuBarLabel`), the
/// system icons and the clock. The strip goes past the trailing edge of the stage, and the
/// stage cuts it there, as the menu bar goes to the edge of the screen.
struct MenuBarStrip: View {
    let health: HealthSummary
    /// A text on the leading side, for example the meaning of the icon.
    var caption: LocalizedStringKey?
    /// `true` shows the icon as selected, as after a click.
    var isSelected = false

    var body: some View {
        HStack(spacing: 14) {
            if let caption {
                Text(caption)
                    .fontWeight(.semibold)
            }

            Spacer(minLength: 0)

            MenuBarLabel(health: health)
                .labelStyle(.iconOnly)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.white.opacity(isSelected ? 0.24 : 0), in: .capsule)
            Image(systemName: "wifi")
            Image(systemName: "battery.100percent")
            Image(systemName: "switch.2")
            Text(verbatim: "9:41")
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.leading, 14)
        .padding(.trailing, 12 + overflow)
        .frame(
            width: WelcomeLayout.stageWidth - WelcomeLayout.stageInset + overflow,
            height: WelcomeLayout.menuBarHeight
        )
        .background {
            let shape = RoundedRectangle(cornerRadius: WelcomeLayout.menuBarRadius)
            shape
                .fill(WelcomePalette.appWindow)
                .overlay { shape.strokeBorder(WelcomePalette.appEdge) }
        }
    }

    /// The part of the strip after the trailing edge of the stage. The stage cuts it, with
    /// its round corners and its edge.
    private var overflow: CGFloat { WelcomeLayout.menuBarRadius }
}
