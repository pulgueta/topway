import SwiftUI

/// The first row of the projects list. It opens the usage screen.
struct SpendRow: View {
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: Layout.controlSpacing) {
                Image(systemName: "chart.bar")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text("Usage and cost")
                    .lineLimit(1)

                Spacer(minLength: Layout.controlSpacing)

                // Always visible, to show that the row opens a screen.
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(RowButtonStyle())
        .help("Show the usage and the cost of this billing period.")
        .accessibilityLabel("Usage and cost")
        .accessibilityHint("Shows the usage and the cost of this billing period.")
    }
}

#Preview {
    SpendRow(onTap: {})
        .frame(width: Layout.windowWidth)
}
