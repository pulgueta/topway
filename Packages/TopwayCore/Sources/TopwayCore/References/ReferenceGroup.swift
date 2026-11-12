/// The variables of one namespace that the editor can insert as references.
public struct ReferenceGroup: Hashable, Identifiable, Sendable {
    public let namespace: ReferenceNamespace
    public let variableNames: [String]

    public var id: ReferenceNamespace { namespace }

    public init(namespace: ReferenceNamespace, variableNames: [String]) {
        self.namespace = namespace
        self.variableNames = variableNames
    }

    /// The name of the group in the menu.
    public var title: String {
        switch namespace {
        case .sameService: "This service"
        case .shared: "Shared variables"
        case .service(let name): name
        }
    }

    public var targets: [ReferenceTarget] {
        variableNames.map { ReferenceTarget(namespace: namespace, variableName: $0) }
    }
}
