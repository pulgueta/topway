/// Gives one overall health from the latest deployment status of each service in each
/// environment.
///
/// The rule:
/// - `FAILED` and `CRASHED` are failing. One failing service makes the health failing.
/// - `BUILDING`, `DEPLOYING`, `INITIALIZING`, `NEEDS_APPROVAL`, `QUEUED`, `REMOVING` and `WAITING`
///   are in progress. They make the health in progress if no service fails.
/// - `SUCCESS`, `REMOVED`, `SKIPPED` and `SLEEPING` are healthy. `REMOVED` and `SKIPPED` mean that
///   no deployment needs an action. `SLEEPING` means that Railway stopped an idle service on
///   purpose. An unknown status also counts as healthy, so it cannot cause a false alert.
/// - No services gives healthy.
public struct HealthSummary: Sendable {
    static let failingStatuses: Set = ["FAILED", "CRASHED"]
    static let inProgressStatuses: Set = [
        "BUILDING", "DEPLOYING", "INITIALIZING", "NEEDS_APPROVAL", "QUEUED", "REMOVING", "WAITING",
    ]

    public let health: Health
    /// The failing services, in the order of the projects.
    public let failing: [ServiceStatus]

    public init(projects: [Project]) {
        let statuses = projects.flatMap(\.serviceStatuses)
        failing = statuses.filter { Self.failingStatuses.contains($0.status) }
        if !failing.isEmpty {
            health = .failing
        } else if statuses.contains(where: { Self.inProgressStatuses.contains($0.status) }) {
            health = .inProgress
        } else {
            health = .healthy
        }
    }
}
