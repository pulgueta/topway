public enum AlertRules {
    /// Compares two snapshots of the service statuses and gives the alerts.
    ///
    /// - A change to `FAILED` gives `failed`. A change to `CRASHED` gives `crashed`.
    /// - A change from `FAILED` or `CRASHED` to `SUCCESS` gives `recovered`.
    /// - No `previous` snapshot (the first load) gives no alerts.
    /// - A status that did not change, a new service and a removed service give no alerts.
    /// - A service in a muted project gives no alerts.
    public static func alerts(
        from previous: [ServiceStatus]?, to current: [ServiceStatus],
        mutedProjectIds: Set<String>
    ) -> [HealthAlert] {
        guard let previous else { return [] }
        return current.compactMap { service in
            guard !mutedProjectIds.contains(service.projectId),
                let earlier = previous.first(where: {
                    $0.environmentId == service.environmentId && $0.serviceId == service.serviceId
                }), earlier.status != service.status,
                let kind = kind(from: earlier.status, to: service.status)
            else { return nil }
            return HealthAlert(kind: kind, service: service)
        }
    }

    private static func kind(from earlier: String, to status: String) -> AlertKind? {
        switch status {
        case "FAILED": .failed
        case "CRASHED": .crashed
        case "SUCCESS" where HealthSummary.failingStatuses.contains(earlier): .recovered
        default: nil
        }
    }
}
