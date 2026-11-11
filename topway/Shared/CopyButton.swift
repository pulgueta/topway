import SwiftUI

/// A button that copies and then shows "Copied" for 2 seconds, so the user sees the result.
/// The caller sets the button style and the label style.
struct CopyButton: View {
    let title: String
    let action: () -> Void

    @State private var isCopied = false

    var body: some View {
        Button(isCopied ? "Copied" : title, systemImage: isCopied ? "checkmark" : "doc.on.doc") {
            action()
            isCopied = true
            AccessibilityNotification.Announcement("Copied").post()
        }
        // The task stops when the button goes away, so no timer stays.
        .task(id: isCopied) {
            guard isCopied else { return }
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                isCopied = false
            }
        }
    }
}
