public struct RailwayEnvironment: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// Railway sets this when it soft-deletes the environment.
    let deletedAt: String?
    let serviceInstances: ServiceInstanceConnection

    public init(id: String, name: String) {
        self.init(id: id, name: name, instances: [])
    }

    init(id: String, name: String, deletedAt: String? = nil, instances: [ServiceInstance]) {
        self.id = id
        self.name = name
        self.deletedAt = deletedAt
        self.serviceInstances = ServiceInstanceConnection(
            edges: instances.map { ServiceInstanceEdge(node: $0) })
    }

    var instanceList: [ServiceInstance] {
        serviceInstances.edges.map(\.node)
    }
}
