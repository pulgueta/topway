public struct ServiceEdge: Decodable, Hashable, Sendable {
    let node: Service

    public init(node: Service) {
        self.node = node
    }
}
