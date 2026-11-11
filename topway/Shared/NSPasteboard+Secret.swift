import AppKit

extension NSPasteboard {
    /// Copies a secret. The `org.nspasteboard.ConcealedType` mark tells clipboard managers
    /// not to keep it. The text still pastes as plain text.
    func setSecret(_ string: String) {
        let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        clearContents()
        setString(string, forType: .string)
        setString(string, forType: concealed)
    }
}
