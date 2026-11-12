/// One action that the error screen offers after a load fails.
public enum RecoveryAction: Sendable, Equatable {
    /// Send the request again.
    case retry
    /// Open Settings, to change the token or the Workspace ID.
    case openSettings
    /// Show sample data. Topway then does not connect to Railway.
    case useSampleData
}
