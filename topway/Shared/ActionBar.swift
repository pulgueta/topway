import SwiftUI

/// The bottom bar of a screen. `status` says what the screen shows, on the leading side.
/// `actions` are the actions of the screen, on the trailing side. Each action has a text
/// label, and at most one action is prominent.
struct ActionBar<Status: View, Actions: View>: View {
    @ViewBuilder var status: Status
    @ViewBuilder var actions: Actions

    var body: some View {
        HStack(spacing: Layout.controlSpacing) {
            status
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: Layout.controlSpacing)

            // One container draws the glass of all buttons in one pass.
            GlassEffectContainer(spacing: Layout.controlSpacing) {
                HStack(spacing: Layout.controlSpacing) {
                    actions
                }
            }
        }
        .padding(.horizontal, Layout.barPadding)
        .padding(.vertical, 10)
    }
}
