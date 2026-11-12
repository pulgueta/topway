import TopwayCore

/// The steps of `ServiceView`. Escape and the back button go to `overview`.
enum ServiceDestination: Equatable {
    /// The tabs: variables and deployments.
    case overview
    /// The variable editor. `nil` adds a variable.
    case editVariable(EnvironmentVariable?)
    case logs(Deployment)
    /// The name of the service and its settings in the selected environment.
    case settings
    /// The domains of the service in the selected environment.
    case domains
}
