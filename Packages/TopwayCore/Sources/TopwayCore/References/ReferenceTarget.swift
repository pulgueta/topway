/// The variable that a Railway reference points to.
public struct ReferenceTarget: Hashable, Sendable {
    public let namespace: ReferenceNamespace
    public let variableName: String

    public init(namespace: ReferenceNamespace, variableName: String) {
        self.namespace = namespace
        self.variableName = variableName
    }

    /// The text between the braces, for example `postgres.DATABASE_URL`.
    public var expression: String {
        switch namespace {
        case .sameService: variableName
        case .shared: "shared.\(variableName)"
        case .service(let name): "\(name).\(variableName)"
        }
    }

    /// The reference as a variable value, for example `${{postgres.DATABASE_URL}}`.
    public var template: String {
        "${{\(expression)}}"
    }
}
