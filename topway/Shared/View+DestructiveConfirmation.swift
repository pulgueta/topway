import SwiftUI

extension View {
    /// Presents a floating Liquid Glass confirmation over this view, and stops input to
    /// this view while the dialog is open. Attach to a view that fills the popover so
    /// the dimmed backdrop covers the whole surface.
    func destructiveConfirmation(
        request: ConfirmationRequest?,
        isLoading: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        disabled(request != nil)
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
            .animation(.easeInOut(duration: 0.2), value: request?.id)
    }
}
