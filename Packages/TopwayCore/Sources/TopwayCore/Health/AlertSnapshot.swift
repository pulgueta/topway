/// Keeps the last settled state of each service in each environment, and gives the alerts
/// when a new load changes it.
///
/// A status is settled when it is not in progress (see `HealthSummary`). An in-progress
/// status does not replace the last settled state. The rule:
/// - A settled `FAILED` gives `failed`, and a settled `CRASHED` gives `crashed`, when the last
///   settled state has a different status or a different deployment ID.
/// - A settled `SUCCESS` after a settled `FAILED` or `CRASHED` gives `recovered`.
/// - The first load gives no alerts. A new service and a removed service give no alerts.
/// - A service in a muted project gives no alerts, but its state still changes.
public struct AlertSnapshot: Sendable {
    /// The services of the latest load.
    private var serviceKeys: Set<String> = []
    /// The last settled status of each service. A service that was only in progress has none.
    private var settled: [String: ServiceStatus] = [:]

    /// Starts with the first load, which gives no alerts.
    public init(statuses: [ServiceStatus]) {
        keep(statuses)
    }

    /// Compares the new load with the snapshot, keeps the new states and gives the alerts.
    public mutating func update(
        with statuses: [ServiceStatus], mutedProjectIds: Set<String>
    ) -> [HealthAlert] {
        let alerts = statuses.compactMap { status -> HealthAlert? in
            let key = Self.key(of: status)
            guard serviceKeys.contains(key), !mutedProjectIds.contains(status.projectId),
                let kind = Self.kind(of: status, after: settled[key])
            else { return nil }
            return HealthAlert(kind: kind, service: status)
        }
        keep(statuses)
        return alerts
    }

    private mutating func keep(_ statuses: [ServiceStatus]) {
        var next: [String: ServiceStatus] = [:]
        for status in statuses {
            let key = Self.key(of: status)
            next[key] =
                HealthSummary.inProgressStatuses.contains(status.status) ? settled[key] : status
        }
        serviceKeys = Set(statuses.map(Self.key(of:)))
        settled = next
    }

    private static func kind(of status: ServiceStatus, after earlier: ServiceStatus?)
        -> AlertKind?
    {
        switch status.status {
        case "FAILED", "CRASHED":
            guard earlier?.status != status.status || earlier?.deploymentId != status.deploymentId
            else { return nil }
            return status.status == "FAILED" ? .failed : .crashed
        case "SUCCESS":
            guard let earlier, HealthSummary.failingStatuses.contains(earlier.status) else {
                return nil
            }
            return .recovered
        default:
            return nil
        }
    }

    private static func key(of status: ServiceStatus) -> String {
        "\(status.environmentId)/\(status.serviceId)"
    }
}
