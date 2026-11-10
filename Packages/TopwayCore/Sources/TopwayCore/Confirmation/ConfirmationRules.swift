public enum ConfirmationRules {
    public static func typedTextMatches(_ typedText: String, targetName: String) -> Bool {
        typedText == targetName
    }

    public static func isProduction(environmentName: String) -> Bool {
        environmentName.lowercased() == "production"
    }
}
