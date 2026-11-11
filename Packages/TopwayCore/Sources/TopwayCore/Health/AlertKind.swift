/// The change in a service that gives an alert.
public enum AlertKind: Sendable {
    /// The latest deployment changed to `FAILED`.
    case failed
    /// The latest deployment changed to `CRASHED`.
    case crashed
    /// The latest deployment changed from `FAILED` or `CRASHED` to `SUCCESS`.
    case recovered
}
