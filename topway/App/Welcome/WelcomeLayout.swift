import SwiftUI

/// The sizes and spaces of the welcome window. `DESIGN.md` gives the rules.
enum WelcomeLayout {
    /// The fixed size of the content. The window has no title bar, but macOS keeps its area
    /// (32 points) above the content. The window is then 780 × 488 points (16:10).
    static let contentWidth: CGFloat = 780
    static let contentHeight: CGFloat = 456
    /// The space between the window edge and the text, and below the bottom bar.
    static let margin: CGFloat = 40
    /// The width of the text column.
    static let textWidth: CGFloat = 288
    /// The leading edge of the stage: the margin, the text and the same space again.
    static let stageLeading: CGFloat = margin + textWidth + margin
    /// The width of the stage. The stage goes to the trailing and bottom edges of the window.
    static let stageWidth: CGFloat = contentWidth - stageLeading
    /// The top of the stage. With the title bar area, it is 40 points below the window top.
    static let stageTop: CGFloat = 8
    /// The size of the 45° cut at the top leading corner of the stage.
    static let stageCut: CGFloat = 32
    /// The space between the leading and top edges of the stage and the copy of the app.
    static let stageInset: CGFloat = 28
    /// The top of the text column. The line of the headline has about 10 points above its
    /// capitals, so the capitals are then level with the top of the copy of the app
    /// (`stageTop + stageInset`).
    static let textTop: CGFloat = 26
    /// The headline: semibold, with tight tracking (about −0.03 em) and tight leading.
    static let headlineSize: CGFloat = 34
    static let headlineTracking: CGFloat = -1
    /// The space between the headline, the message and the notes.
    static let textSpacing: CGFloat = 16
    /// The distance that the text of a page moves when it comes in or goes out.
    static let pageShift: CGFloat = 36
    /// The corner radius of the copy of the menu bar window.
    static let appWindowRadius: CGFloat = 16
    /// The height of the copy of the menu bar, and its corner radius.
    static let menuBarHeight: CGFloat = 28
    static let menuBarRadius: CGFloat = 8
    /// The size of a dot of the page indicator. The dot of the current page is wider.
    static let dotSize: CGFloat = 7
    static let currentDotWidth: CGFloat = 20
}
