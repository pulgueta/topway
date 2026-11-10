/// How much damage an action can do. The level sets the confirmation that the user sees.
public enum HarmLevel: Sendable {
    /// The action runs at once.
    case low
    /// The user confirms in a dialog.
    case medium
    /// The user types the exact name of the target.
    case high

    public var needsDialog: Bool {
        self != .low
    }

    public var needsTypedName: Bool {
        self == .high
    }

    public func canConfirm(typedText: String, targetName: String) -> Bool {
        !needsTypedName || ConfirmationRules.typedTextMatches(typedText, targetName: targetName)
    }
}
