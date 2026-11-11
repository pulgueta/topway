import Foundation

public enum ConfirmationRules {
    public static func typedTextMatches(_ typedText: String, targetName: String) -> Bool {
        typedText == targetName
    }

    public static func isProduction(environmentName: String) -> Bool {
        environmentName.lowercased() == "production"
    }

    public static func variableSaveHarm(
        name: String, isEditing: Bool, existingNames: Set<String>?
    ) -> HarmLevel {
        guard !isEditing, let existingNames else { return .medium }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        return existingNames.contains(trimmedName) ? .medium : .low
    }
}
