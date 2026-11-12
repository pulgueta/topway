extension String {
    /// Puts a text in place of a range, and gives the index just after the new text.
    /// The index comes from the UTF-8 length of the start, so it is an index of the new text.
    func edit(replacing range: Range<String.Index>, with replacement: String) -> (
        text: String, cursor: String.Index
    ) {
        let start = String(self[..<range.lowerBound]) + replacement
        let text = start + String(self[range.upperBound...])
        return (text, text.utf8.index(text.startIndex, offsetBy: start.utf8.count))
    }
}
