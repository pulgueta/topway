public struct Project: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// Railway sets this when it soft-deletes a project or schedules its deletion.
    let deletedAt: String?
    let services: ServiceConnection
    let environments: EnvironmentConnection

    public init(
        id: String,
        name: String,
        deletedAt: String? = nil,
        services: ServiceConnection,
        environments: EnvironmentConnection
    ) {
        self.id = id
        self.name = name
        self.deletedAt = deletedAt
        self.services = services
        self.environments = environments
    }

    public var serviceList: [Service] {
        services.edges.map { $0.node }
    }

    public var environmentList: [RailwayEnvironment] {
        environments.edges.map { $0.node }
    }

    /// The name of the production environment, if the project has one.
    public var productionEnvironmentName: String? {
        environmentList.first {
            ConfirmationRules.isProduction(environmentName: $0.name)
        }?.name
    }
}
