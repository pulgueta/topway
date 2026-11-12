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

    /// The text that a row shows: the expression, or the name and "in this service" for a
    /// variable of the same service.
    public var displayName: String {
        namespace == .sameService ? "\(variableName) in this service" : expression
    }

    /// The reference as a variable value, for example `${{postgres.DATABASE_URL}}`.
    public var template: String {
        "${{\(expression)}}"
    }

    /// Puts the template in place of a range, for example the selection of the editor.
    /// The cursor goes after the template.
    public func insert(into text: String, replacing range: Range<String.Index>) -> (
        text: String, cursor: String.Index
    ) {
        text.edit(replacing: range, with: template)
    }
}
