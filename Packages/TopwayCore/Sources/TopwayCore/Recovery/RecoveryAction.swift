/// One action that the error screen offers after a load fails.
public enum RecoveryAction: Sendable, Equatable {
    /// Send the request again.
    case retry
    /// Open Settings, to select a different workspace.
    case openSettings
    /// Sign in with Railway again, for a new token and a new selection of workspaces.
    case signIn
    /// Show sample data. Topway then does not connect to Railway.
    case useSampleData
}
