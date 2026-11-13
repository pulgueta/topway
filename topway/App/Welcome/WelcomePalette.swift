import SwiftUI

/// The neutral colors of the welcome window. They are the colors of the App Store
/// screenshots of Topway: a warm stone ground and a darker stone stage. The only other
/// colors come from the copies of the app (the system blue and the status colors).
/// `DESIGN.md` has the contrast numbers.
enum WelcomePalette {
    /// The background of the window.
    static let ground = WelcomeColor(light: rgb(0xEC, 0xEB, 0xE7), dark: rgb(0x1B, 0x1A, 0x18))
    /// The stage that holds the copy of the app.
    static let stage = WelcomeColor(light: rgb(0xD5, 0xD2, 0xCA), dark: rgb(0x2A, 0x29, 0x26))
    /// The headline, the dot of the current page and the fill of the primary button.
    static let ink = WelcomeColor(light: rgb(0x15, 0x15, 0x13), dark: rgb(0xF1, 0xF0, 0xEC))
    /// The message and the notes. With Increase Contrast, it is the same as `ink`.
    static let text = WelcomeColor(
        light: rgb(0x3A, 0x39, 0x35), dark: rgb(0xB9, 0xB6, 0xAE),
        increasedContrastLight: rgb(0x15, 0x15, 0x13), increasedContrastDark: rgb(0xF1, 0xF0, 0xEC))
    /// The dots of the other pages. With Increase Contrast, they are the same as `text`.
    static let dot = WelcomeColor(
        light: rgb(0x7A, 0x77, 0x6F), dark: rgb(0x7A, 0x77, 0x6F),
        increasedContrastLight: rgb(0x3A, 0x39, 0x35), increasedContrastDark: rgb(0xB9, 0xB6, 0xAE))
    /// The fill of the copies of the menu bar window and of the menu bar (`#202020`), as in
    /// the screenshots. It does not change with the appearance, because the copies are dark.
    static let appWindow = rgb(0x20, 0x20, 0x20)
    /// The thin light edge of the copies, as the edge of a dark window. It keeps a dark copy
    /// apart from the dark stage of the dark appearance, with no shadow.
    static let appEdge = WelcomeColor(
        light: .white.opacity(0.16), dark: .white.opacity(0.16),
        increasedContrastLight: .white.opacity(0.5), increasedContrastDark: .white.opacity(0.5))

    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}
