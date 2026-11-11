public struct ServiceConnection: Decodable, Hashable, Sendable {
    let edges: [ServiceEdge]

    public init(edges: [ServiceEdge]) {
        self.edges = edges
    }
}
