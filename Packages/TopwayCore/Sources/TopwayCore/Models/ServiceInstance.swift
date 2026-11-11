/// A service in one environment, with its latest deployment.
struct ServiceInstance: Decodable, Hashable, Sendable {
    let environmentId: String
    /// `nil` when the service has no deployment in the environment.
    let latestDeployment: Deployment?
}
