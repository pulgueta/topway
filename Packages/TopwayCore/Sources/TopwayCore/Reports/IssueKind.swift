/// A kind of problem report. Each kind has an issue form in `.github/ISSUE_TEMPLATE`.
public enum IssueKind: Sendable, Equatable, CaseIterable {
    /// Topway did something wrong, but it did not quit.
    case bug
    /// Topway quit when the user did not tell it to quit.
    case crash
}
