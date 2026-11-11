/// A log line with an ID that stays the same while the line is in a `LogBuffer`.
public struct LogEntry: Identifiable, Hashable, Sendable {
    public let id: Int
    public let line: LogLine
}
