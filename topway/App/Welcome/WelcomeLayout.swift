import SwiftUI

/// The sizes and spaces of the welcome window. `DESIGN.md` gives the rules.
enum WelcomeLayout {
    /// The fixed width of the window. The height follows the tallest page, so the window
    /// does not change its size when the page changes.
    static let windowWidth: CGFloat = 560
    /// The largest width of the text of a page, so that a line stays easy to read.
    static let textWidth: CGFloat = 440
    /// The horizontal space between the window edge and the content.
    static let sidePadding: CGFloat = 28
    /// The space between the title bar area and the picture of a page.
    static let topPadding: CGFloat = 12
    /// The height of the picture at the top of each page. All pages use the same height,
    /// so the headings are at the same position.
    static let heroHeight: CGFloat = 150
    /// The space between the picture and the heading.
    static let heroSpacing: CGFloat = 26
    /// The space between the heading, the message and the notes.
    static let textSpacing: CGFloat = 10
    /// The space between the content and the bottom bar, and below the bottom bar.
    static let barSpacing: CGFloat = 22
    /// The distance that a page moves when it comes in or goes out.
    static let pageShift: CGFloat = 36
    /// The size of the app icon on the first page.
    static let appIconSize: CGFloat = 116
    /// The size of a dot of the page indicator. The dot of the current page is wider.
    static let dotSize: CGFloat = 7
    static let currentDotWidth: CGFloat = 20
}
