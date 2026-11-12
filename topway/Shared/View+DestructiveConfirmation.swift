import SwiftUI

extension View {
    /// Shows a Liquid Glass confirmation above this view, and stops input to this view
    /// while the dialog is open. Use it on a view that fills the menu bar window, so the
    /// dimmed backdrop covers all content.
    func destructiveConfirmation(
        request: ConfirmationRequest?,
        isLoading: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        disabled(request != nil)
            // VoiceOver and Voice Control must not get to the content behind the dialog.
            .accessibilityHidden(request != nil)
            .overlay {
                if let request {
                    GlassConfirmationDialog(
                        request: request,
                        isLoading: isLoading,
                        onConfirm: onConfirm,
                        onCancel: onCancel
                    )
                    .id(request.id)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
            .animation(.screenChange, value: request?.id)
    }
}
