import SwiftUI

/// The fill of the small pictures of the app on the welcome pages. It is a deep violet,
/// not glass: `DESIGN.md` keeps glass on the control layer.
struct WelcomeSurface: View {
    let cornerRadius: CGFloat
    /// `true` for a picture that is in front of another picture.
    var isOpaque = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(
                WelcomePalette.surface.opacity(
                    isOpaque || reduceTransparency ? 1 : WelcomePalette.surfaceOpacity)
            )
            .overlay {
                shape.strokeBorder(.white.opacity(contrast == .increased ? 0.8 : 0.2))
            }
    }
}
