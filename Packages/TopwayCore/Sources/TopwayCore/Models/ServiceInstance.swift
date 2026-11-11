/// A service in one environment, with its latest deployment.
struct ServiceInstance: Decodable, Hashable, Sendable {
    let serviceId: String
    /// `nil` when the service has no deployment in the environment.
    let latestDeployment: Deployment?
    /// Railway sets this when it soft-deletes the service in the environment.
    let deletedAt: String?

    init(serviceId: String, latestDeployment: Deployment?, deletedAt: String? = nil) {
        self.serviceId = serviceId
        self.latestDeployment = latestDeployment
        self.deletedAt = deletedAt
    }
}
