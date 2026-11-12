import SwiftUI

/// The top bar of a screen below the projects list. The back button shows the name of the
/// screen that it opens, so the user knows where it goes. `trailing` holds at most one control.
struct ScreenHeader<Trailing: View>: View {
    let title: String
    let backTitle: String
    let onBack: () -> Void
    @ViewBuilder var trailing: Trailing

    var body: some View {
        GlassEffectContainer(spacing: Layout.controlSpacing) {
            HStack(spacing: Layout.controlSpacing) {
                // The two sides keep the same least width, so the title stays in the center.
                HStack(spacing: 0) {
                    Button(backTitle, systemImage: "chevron.backward") { onBack() }
                        .buttonStyle(.glass)
                        .help("Go back to \(backTitle) (Escape)")
                        .accessibilityLabel("Back to \(backTitle)")
                    Spacer(minLength: 0)
                }
                .frame(minWidth: Layout.headerSideWidth)
                .fixedSize()

                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    trailing
                }
                .frame(minWidth: Layout.headerSideWidth)
                .fixedSize()
            }
        }
        .padding(.horizontal, Layout.barPadding)
        .padding(.vertical, 10)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, backTitle: String, onBack: @escaping () -> Void) {
        self.init(title: title, backTitle: backTitle, onBack: onBack) { EmptyView() }
    }
}
