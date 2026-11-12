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

    /// The environments of the project, without the environments that Railway deleted.
    public var environmentList: [RailwayEnvironment] {
        environments.edges.map { $0.node }.filter { $0.deletedAt == nil }
    }

    /// The services that are in an environment, in the order of `serviceList`.
    public func serviceList(in environmentId: String) -> [Service] {
        guard let environment = environmentList.first(where: { $0.id == environmentId }) else {
            return []
        }
        let ids = Set(environment.instanceList.filter { $0.deletedAt == nil }.map(\.serviceId))
        return serviceList.filter { ids.contains($0.id) }
    }

    /// The latest deployment status of each service in each environment.
    /// A service with no deployment in an environment gives no status there. Deleted
    /// environments and deleted services in an environment give no status.
    public var serviceStatuses: [ServiceStatus] {
        let serviceNames = Dictionary(
            serviceList.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        return environmentList.flatMap { environment in
            environment.instanceList.compactMap { instance in
                guard instance.deletedAt == nil, let deployment = instance.latestDeployment,
                    let serviceName = serviceNames[instance.serviceId]
                else { return nil }
                return ServiceStatus(
                    projectId: id, projectName: name, environmentId: environment.id,
                    environmentName: environment.name, serviceId: instance.serviceId,
                    serviceName: serviceName, deploymentId: deployment.id,
                    status: deployment.status)
            }
        }
    }

    /// The name of the production environment, if the project has one.
    public var productionEnvironmentName: String? {
        environmentList.first {
            ConfirmationRules.isProduction(environmentName: $0.name)
        }?.name
    }
}
