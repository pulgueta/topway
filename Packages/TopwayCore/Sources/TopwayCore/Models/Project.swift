public struct Project: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    public let name: String
    let services: ServiceConnection
    let environments: EnvironmentConnection

    public init(
        id: String,
        name: String,
        services: ServiceConnection,
        environments: EnvironmentConnection
    ) {
        self.id = id
        self.name = name
        self.services = services
        self.environments = environments
    }

    public var serviceList: [Service] {
        services.edges.map { $0.node }
    }

    public var environmentList: [RailwayEnvironment] {
        environments.edges.map { $0.node }
    }
}
