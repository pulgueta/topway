import Foundation

/// The reference that the user types: the text after an open `${{` before the cursor.
public struct ReferenceCompletion: Equatable, Sendable {
    /// The typed text after `${{`, with no space at the start.
    public let query: String
    /// The text that a selected target replaces: from `${{` to the cursor, and a `}}` that
    /// is just after the cursor.
    let range: Range<String.Index>

    /// `nil` when the cursor is not in an open reference. A brace or a line break after
    /// the opening ends it.
    public init?(text: String, cursor: String.Index) {
        guard
            let open = text.range(
                of: "${{", options: .backwards, range: text.startIndex..<cursor)
        else { return nil }
        let typed = text[open.upperBound..<cursor]
        guard !typed.contains("}"), !typed.contains(where: \.isNewline) else { return nil }

        query = String(typed.drop(while: \.isWhitespace))
        let end = text[cursor...].hasPrefix("}}") ? text.index(cursor, offsetBy: 2) : cursor
        range = open.upperBound..<end
    }

    /// The targets that have the typed text, with no difference between uppercase and
    /// lowercase letters, in their order.
    public func matches(in targets: [ReferenceTarget], limit: Int = 5) -> [ReferenceTarget] {
        let matching =
            query.isEmpty
            ? targets
            : targets.filter { $0.expression.range(of: query, options: .caseInsensitive) != nil }
        return Array(matching.prefix(limit))
    }

    /// Completes the reference with a target and closes the braces. The cursor goes after
    /// the reference.
    public func insert(_ target: ReferenceTarget, into text: String) -> (
        text: String, cursor: String.Index
    ) {
        text.edit(replacing: range, with: target.expression + "}}")
    }
}
