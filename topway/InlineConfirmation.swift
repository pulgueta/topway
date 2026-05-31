import SwiftUI

/// Inline destructive-action confirmation.
///
/// Used instead of the native `confirmationDialog`/`alert`, which present in a
/// separate window and steal key focus — that causes the `MenuBarExtra(.window)`
/// popover to dismiss itself out from under the dialog. Staying inline keeps
/// everything inside the popover.
@MainActor
struct InlineConfirmation: View {
    let title: String
    let message: String
    var confirmLabel: String = "Delete"
    var isLoading: Bool = false
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                Spacer()
            }

            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity)
                    .disabled(isLoading)

                Button(action: onConfirm) {
                    HStack(spacing: 4) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Deleting…" : confirmLabel)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.regular)
                .disabled(isLoading)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

#Preview {
    InlineConfirmation(
        title: "Delete Project",
        message: "Delete \"My Project\"? This permanently deletes all services, deployments, and data.",
        onConfirm: {},
        onCancel: {}
    )
    .padding()
    .frame(width: 320)
}
