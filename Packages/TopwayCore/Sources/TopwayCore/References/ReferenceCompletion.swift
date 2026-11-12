import Foundation

/// The reference that the user types: the text after an open `${{` before the cursor.
public struct ReferenceCompletion: Equatable, Sendable {
    /// The typed text after `${{`, with no space at the start.
    public let query: String
    /// The text that a selected target replaces: from `${{` to the cursor and, when the
    /// cursor is in a reference that has a close, the rest of that reference with its `}}`.
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
        range = open.upperBound..<Self.end(of: text, after: cursor)
    }

    /// The end of the reference that has the cursor: after its `}}`. With no close on the
    /// same line before the next `${{`, the reference is open, and the end is the cursor,
    /// so the text after it stays.
    private static func end(of text: String, after cursor: String.Index) -> String.Index {
        guard let close = text.range(of: "}}", range: cursor..<text.endIndex) else {
            return cursor
        }
        let inside = text[cursor..<close.lowerBound]
        guard !inside.contains("${{"), !inside.contains(where: \.isNewline) else { return cursor }
        return close.upperBound
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
