import Foundation

/// One Railway reference in a variable value, for example `${{ postgres.DATABASE_URL }}`.
public struct VariableReference: Hashable, Sendable {
    public let target: ReferenceTarget
    /// The range of the full reference in the value, from `${{` to `}}`.
    public let range: Range<String.Index>

    /// Gives the references in a value, in their order. Railway permits spaces inside the
    /// braces. Text that is not a variable name, such as `${{ secret(32) }}`, is not a
    /// reference.
    public static func all(in value: String) -> [VariableReference] {
        var references: [VariableReference] = []
        var searchStart = value.startIndex
        while let open = value.range(of: "${{", range: searchStart..<value.endIndex) {
            guard let close = value.range(of: "}}", range: open.upperBound..<value.endIndex)
            else { break }
            // An opening with no close of its own does not start a reference. The next
            // opening can.
            if let next = value.range(of: "${{", range: open.upperBound..<close.lowerBound) {
                searchStart = next.lowerBound
                continue
            }
            if let target = target(in: value[open.upperBound..<close.lowerBound]) {
                references.append(
                    VariableReference(target: target, range: open.lowerBound..<close.upperBound))
            }
            searchStart = close.upperBound
        }
        return references
    }

    /// The text before the last dot is the namespace, because a service name can have a dot
    /// and a variable name cannot.
    private static func target(in text: Substring) -> ReferenceTarget? {
        let expression = text.trimmingCharacters(in: .whitespaces)
        guard let dot = expression.lastIndex(of: ".") else {
            guard isVariableName(expression) else { return nil }
            return ReferenceTarget(namespace: .sameService, variableName: expression)
        }
        let namespace = String(expression[..<dot])
        let name = String(expression[expression.index(after: dot)...])
        guard !namespace.isEmpty, isVariableName(name) else { return nil }
        return ReferenceTarget(
            namespace: namespace == "shared" ? .shared : .service(namespace), variableName: name)
    }

    /// Letters, digits, underscores and hyphens. Railway permits a hyphen in a shared
    /// variable name, as the Railway CLI shows.
    private static func isVariableName(_ text: String) -> Bool {
        !text.isEmpty
            && text.allSatisfy {
                $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-")
            }
    }
}
