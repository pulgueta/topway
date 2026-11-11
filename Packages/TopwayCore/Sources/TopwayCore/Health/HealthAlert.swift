/// One alert about one service in one environment.
public struct HealthAlert: Hashable, Sendable {
    public let kind: AlertKind
    /// The new status of the service.
    public let service: ServiceStatus
}
