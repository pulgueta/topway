public struct EnvironmentConnection: Decodable, Hashable, Sendable {
    let edges: [EnvironmentEdge]

    public init(edges: [EnvironmentEdge]) {
        self.edges = edges
    }
}
