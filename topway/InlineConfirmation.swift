import SwiftUI

/// A destructive-action confirmation presented as a floating Liquid Glass dialog
/// over a dimmed backdrop, layered inside the current view.
///
/// Used instead of the native `confirmationDialog`/`alert`, which present in a
/// separate window and steal key focus — that dismisses the `MenuBarExtra(.window)`
/// popover out from under the dialog. Layering the dialog inside the popover keeps
/// it open. Present it with the `destructiveConfirmation(...)` modifier, attached
/// to a view that fills the popover so the backdrop covers the whole surface.
@MainActor
struct GlassConfirmationDialog: View {
    let title: String
    let message: String
    var confirmLabel: String = "Delete"
    var isLoading: Bool = false
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            // Dimmed backdrop; tapping outside cancels (unless mid-action).
            Rectangle()
                .fill(.black.opacity(0.3))
                .ignoresSafeArea()
                .contentShape(.rect)
                .onTapGesture {
                    if !isLoading { onCancel() }
                }

            card
                .padding(28)
        }
    }

    private var card: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.red)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))

                Spacer()
            }

            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
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
                .controlSize(.large)
                .disabled(isLoading)
            }
        }
        .padding(18)
        .frame(maxWidth: 264)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

extension View {
    /// Presents a floating Liquid Glass destructive-confirmation dialog over this
    /// view. Attach to a view that fills the popover so the dimmed backdrop covers
    /// the whole surface.
    func destructiveConfirmation(
        isPresented: Bool,
        title: String,
        message: String,
        confirmLabel: String = "Delete",
        isLoading: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        overlay {
            if isPresented {
                GlassConfirmationDialog(
                    title: title,
                    message: message,
                    confirmLabel: confirmLabel,
                    isLoading: isLoading,
                    onConfirm: onConfirm,
                    onCancel: onCancel
                )
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

#Preview {
    VStack {
        Text("Background content")
        Spacer()
    }
    .frame(width: 320, height: 400)
    .destructiveConfirmation(
        isPresented: true,
        title: "Delete Project",
        message: "Delete \"My Project\"? This permanently deletes all services, deployments, and data.",
        onConfirm: {},
        onCancel: {}
    )
}
