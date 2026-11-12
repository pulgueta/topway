import SwiftUI
import TopwayCore

/// Shows the error of a failed action above the bottom bar, while the content stays visible.
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    /// Shows a Retry button when it is set.
    var onRetry: (() -> Void)?
    /// Shows these actions below the message, for example after a rejected token.
    var recoveryActions: [RecoveryAction] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.controlSpacing) {
            messageRow

            if !recoveryActions.isEmpty {
                HStack(spacing: Layout.controlSpacing) {
                    ForEach(recoveryActions, id: \.self) { action in
                        RecoveryButton(action: action, isPrimary: false, onRetry: { onRetry?() })
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.15), in: .rect(cornerRadius: Layout.rowCornerRadius))
        .padding(.horizontal, Layout.barPadding)
        .padding(.top, 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error")
    }

    private var messageRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.controlSpacing) {
            Label {
                Text(message)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .font(.callout)

            Spacer(minLength: 0)

            if let onRetry {
                Button("Retry") { onRetry() }
                    .buttonStyle(.borderless)
            }

            Button("Close message", systemImage: "xmark") { onDismiss() }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Close this message")
        }
    }
}
