/// The change in a service that gives an alert. `AlertSnapshot` has the full rule.
public enum AlertKind: Sendable {
    /// A new settled `FAILED` deployment.
    case failed
    /// A new settled `CRASHED` deployment.
    case crashed
    /// A settled `SUCCESS` after a settled `FAILED` or `CRASHED`.
    case recovered
}
