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

    /// The full text between the braces must be a reference: `NAME`, `shared.NAME` or
    /// `service.NAME`, with spaces only next to the braces. Anything else, for example a
    /// brace, a space or a second dot inside, gives no target. So a malformed value never
    /// shows a part of itself as a target.
    private static func target(in text: Substring) -> ReferenceTarget? {
        let expression = text.trimmingCharacters(in: .whitespaces)
        let parts = expression.split(separator: ".", omittingEmptySubsequences: false)
        switch parts.count {
        case 1:
            guard isVariableName(expression) else { return nil }
            return ReferenceTarget(namespace: .sameService, variableName: expression)
        case 2:
            let namespace = String(parts[0])
            let name = String(parts[1])
            guard isVariableName(name) else { return nil }
            if namespace == "shared" {
                return ReferenceTarget(namespace: .shared, variableName: name)
            }
            guard isServiceName(namespace) else { return nil }
            return ReferenceTarget(namespace: .service(namespace), variableName: name)
        default:
            return nil
        }
    }

    /// An ASCII letter or an underscore, then ASCII letters, digits, underscores and
    /// hyphens. Railway permits a hyphen in a shared variable name, as the Railway CLI shows.
    private static func isVariableName(_ text: String) -> Bool {
        guard let first = text.first, first.isASCII, first.isLetter || first == "_" else {
            return false
        }
        return text.allSatisfy(isNameCharacter)
    }

    /// An ASCII letter, then ASCII letters, digits, underscores and hyphens. This is the
    /// service name that the Railway CLI accepts in a reference (`auto_wrap_reference`).
    private static func isServiceName(_ text: String) -> Bool {
        guard let first = text.first, first.isASCII, first.isLetter else { return false }
        return text.allSatisfy(isNameCharacter)
    }

    private static func isNameCharacter(_ character: Character) -> Bool {
        character.isASCII
            && (character.isLetter || character.isNumber || character == "_" || character == "-")
    }
}
