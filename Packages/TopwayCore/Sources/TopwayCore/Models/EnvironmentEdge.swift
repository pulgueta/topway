public struct EnvironmentEdge: Decodable, Hashable, Sendable {
    let node: RailwayEnvironment

    public init(node: RailwayEnvironment) {
        self.node = node
    }
}
