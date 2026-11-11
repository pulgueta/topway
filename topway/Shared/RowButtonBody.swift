import SwiftUI

/// Draws a row for `RowButtonStyle`. The highlight only shows where the pointer is and
/// that a press registers. It never shows or hides an action.
struct RowButtonBody: View {
    let configuration: ButtonStyle.Configuration

    @State private var isHovered = false

    private var highlight: Double {
        if configuration.isPressed { 0.14 } else if isHovered { 0.07 } else { 0 }
    }

    var body: some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                .primary.opacity(highlight), in: .rect(cornerRadius: Layout.rowCornerRadius)
            )
            .contentShape(.rect(cornerRadius: Layout.rowCornerRadius))
            .onHover { isHovered = $0 }
    }
}
