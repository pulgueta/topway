import SwiftUI

/// The fixed brand colors of the welcome window. They come from the app icon
/// (`Appicon.icon`): a gradient from `#8205FF` to `#B300FF`, and a `#5E17EB` layer.
///
/// All text on these colors is white. The lightest color, `#B300FF`, gives a contrast of
/// 4.82:1 with white, so all text on the gradient is at least 4.5:1. `DESIGN.md` has the
/// numbers.
enum WelcomePalette {
    /// The colors of the 3 × 3 mesh, from the top leading corner, row by row. The top is
    /// the brightest, for the picture. The text is on the darker middle and bottom.
    static let mesh: [Color] = [
        Color(red: 0.369, green: 0.090, blue: 0.922),  // #5E17EB
        Color(red: 0.510, green: 0.020, blue: 1.000),  // #8205FF
        Color(red: 0.702, green: 0.000, blue: 1.000),  // #B300FF
        Color(red: 0.239, green: 0.059, blue: 0.722),
        Color(red: 0.416, green: 0.039, blue: 0.902),
        Color(red: 0.510, green: 0.020, blue: 1.000),
        Color(red: 0.122, green: 0.031, blue: 0.400),
        Color(red: 0.180, green: 0.039, blue: 0.561),
        Color(red: 0.298, green: 0.059, blue: 0.788),
    ]

    /// The same mesh, 28% darker, for Increase Contrast. White text on it is at least 7.8:1.
    static let increasedContrastMesh: [Color] = [
        Color(red: 0.266, green: 0.065, blue: 0.664),
        Color(red: 0.367, green: 0.014, blue: 0.720),
        Color(red: 0.505, green: 0.000, blue: 0.720),
        Color(red: 0.172, green: 0.042, blue: 0.520),
        Color(red: 0.300, green: 0.028, blue: 0.649),
        Color(red: 0.367, green: 0.014, blue: 0.720),
        Color(red: 0.088, green: 0.022, blue: 0.288),
        Color(red: 0.130, green: 0.028, blue: 0.404),
        Color(red: 0.215, green: 0.042, blue: 0.567),
    ]

    /// The fill of the small pictures of the app (`WelcomeSurface`): a deep violet.
    static let surface = Color(red: 0.075, green: 0.020, blue: 0.250)
    /// The opacity of `surface`. Reduce Transparency makes it 1.
    static let surfaceOpacity = 0.6
    /// The fill of a prominent button in the pictures (`#8205FF`).
    static let accent = Color(red: 0.510, green: 0.020, blue: 1.000)
}
