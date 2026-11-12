/// A link: the variables of `from` that have one or more references to `to`.
public struct ServiceGraphEdge: Hashable, Sendable {
    public let from: ServiceGraphNode
    public let to: ServiceGraphNode
    /// The names of the variables of `from`, sorted, each one time.
    public let variableNames: [String]

    public init(from: ServiceGraphNode, to: ServiceGraphNode, variableNames: [String]) {
        self.from = from
        self.to = to
        self.variableNames = variableNames
    }
}
