/// The log lines that the logs screen shows. It keeps the newest `capacity` lines only.
public struct LogBuffer: Sendable {
    public static let capacity = 1_000

    public private(set) var entries: [LogEntry] = []
    private var nextId = 0

    public init() {}

    public mutating func append(_ lines: [LogLine]) {
        entries.append(
            contentsOf: lines.enumerated().map {
                LogEntry(id: nextId + $0.offset, line: $0.element)
            })
        nextId += lines.count
        if entries.count > Self.capacity {
            entries.removeFirst(entries.count - Self.capacity)
        }
    }

    /// One line for each entry: the timestamp, then the message.
    public var text: String {
        entries.map { "\($0.line.timestamp) \($0.line.message)" }.joined(separator: "\n")
    }
}
