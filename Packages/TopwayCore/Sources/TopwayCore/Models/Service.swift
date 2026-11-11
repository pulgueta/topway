public struct Service: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    public let name: String
    let serviceInstances: ServiceInstanceConnection

    public init(id: String, name: String) {
        self.init(id: id, name: name, instances: [])
    }

    init(id: String, name: String, instances: [ServiceInstance]) {
        self.id = id
        self.name = name
        self.serviceInstances = ServiceInstanceConnection(
            edges: instances.map { ServiceInstanceEdge(node: $0) })
    }

    var instanceList: [ServiceInstance] {
        serviceInstances.edges.map(\.node)
    }
}
