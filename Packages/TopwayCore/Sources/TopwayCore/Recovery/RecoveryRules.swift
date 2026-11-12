public enum RecoveryRules {
    /// The actions for a failed load. The most useful action is first.
    ///
    /// A rejected token fails again on each retry, so the user gets no retry. The user changes
    /// the token in Settings or uses sample data. Sample mode has no token and no settings
    /// to change, so it offers only a retry.
    public static func actions(isTokenRejected: Bool, isSampleMode: Bool) -> [RecoveryAction] {
        if isSampleMode {
            return [.retry]
        }
        if isTokenRejected {
            return [.openSettings, .useSampleData]
        }
        return [.retry, .openSettings]
    }
}
