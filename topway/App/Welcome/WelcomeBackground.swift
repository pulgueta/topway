import SwiftUI

/// The full background of the welcome window: a mesh of the brand colors. It does not move.
struct WelcomeBackground: View {
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        // The middle points are a little off the grid, so the colors flow in soft curves.
        // `smoothsColors: false` mixes the colors in straight lines. The mix is then
        // never lighter than the lightest color, so the contrast numbers stay true.
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.55], [0.62, 0.42], [1, 0.48],
                [0, 1], [0.45, 1], [1, 1],
            ],
            colors: contrast == .increased
                ? WelcomePalette.increasedContrastMesh : WelcomePalette.mesh,
            smoothsColors: false
        )
        .accessibilityHidden(true)
    }
}

#Preview {
    WelcomeBackground()
        .frame(width: WelcomeLayout.windowWidth, height: 480)
}
