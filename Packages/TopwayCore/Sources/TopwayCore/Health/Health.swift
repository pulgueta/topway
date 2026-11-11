/// The overall health of the projects.
public enum Health: Sendable {
    /// No service fails, and no build or deploy runs.
    case healthy
    /// A build or a deploy runs, and no service fails.
    case inProgress
    /// One or more services failed or crashed.
    case failing
}
