/// The status of the latest deployment of one service in one environment.
public struct ServiceStatus: Hashable, Sendable {
    public let projectId: String
    public let projectName: String
    public let environmentId: String
    public let environmentName: String
    public let serviceId: String
    public let serviceName: String
    let deploymentId: String
    /// The Railway deployment status, for example `SUCCESS` or `CRASHED`.
    let status: String
}
