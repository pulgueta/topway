import TopwayCore

enum VariablesViewDestination: Equatable {
    case list
    case edit(EnvironmentVariable?)
    case deployments
    case logs(Deployment)
}
