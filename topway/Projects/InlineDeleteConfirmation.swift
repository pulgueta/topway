import SwiftUI

struct InlineDeleteConfirmation: View {
    let title: String
    let message: String
    var isLoading: Bool = false
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var isDeleteHovered = false
    @State private var isCancelHovered = false

    var body: some View {
        VStack(spacing: 12) {
            // Warning Icon and Title
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                }
            }

            // Message
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            // Buttons
            HStack(spacing: 8) {
                // Cancel Button
                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isCancelHovered ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    isCancelHovered
                                        ? Color.primary.opacity(0.1) : Color.primary.opacity(0.05))
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isCancelHovered = hovering
                }
                .disabled(isLoading)

                // Delete Button
                Button {
                    onConfirm()
                } label: {
                    HStack(spacing: 4) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        }
                        Text(isLoading ? "Deleting..." : "Delete")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                isLoading
                                    ? Color.red.opacity(0.6)
                                    : (isDeleteHovered ? Color.red.opacity(0.8) : Color.red))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isDeleteHovered = hovering
                }
                .disabled(isLoading)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
