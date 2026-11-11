import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    /// Shows a Retry button when it is set.
    var onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)

            Text(message)
                .font(.system(size: 11))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            if let onRetry {
                Button("Retry") { onRetry() }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.borderless)
            }

            Button("Close message", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }
}
