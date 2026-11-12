import SwiftUI

/// The sizes and spaces that all screens use. `DESIGN.md` gives the rules.
enum Layout {
    /// The fixed size of the menu bar window. A fixed size keeps the window stable
    /// when the content changes.
    static let windowWidth: CGFloat = 360
    static let windowHeight: CGFloat = 480

    /// The space between the window edge and the content of a bar.
    static let barPadding: CGFloat = 12
    /// The space between two controls in a bar or in a row.
    static let controlSpacing: CGFloat = 8
    /// The horizontal space between the window edge and list content.
    static let contentInset: CGFloat = 12
    /// The corner radius of a row highlight and of a message.
    static let rowCornerRadius: CGFloat = 8
    /// The width that each side of a screen header keeps, so the title stays in the center.
    static let headerSideWidth: CGFloat = 112
}
