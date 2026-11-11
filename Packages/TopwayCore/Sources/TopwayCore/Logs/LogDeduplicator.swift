/// Removes log lines that a stream already gave.
///
/// A line is a duplicate when its timestamp, message and severity are equal to a line that
/// was seen. A subscription that connects again, and each poll, give the latest lines again.
/// Only the last `capacity` lines are kept, so memory stays fixed. Railway can add a line
/// with an earlier timestamp, so this type does not compare times.
struct LogDeduplicator {
    private let capacity: Int
    private var seen: Set<LogLine> = []
    /// The seen lines, oldest first.
    private var order: [LogLine] = []

    init(capacity: Int) {
        self.capacity = capacity
    }

    mutating func newLines(in lines: [LogLine]) -> [LogLine] {
        let new = lines.filter { seen.insert($0).inserted }
        order.append(contentsOf: new)
        if order.count > capacity {
            let expired = order.count - capacity
            seen.subtract(order[..<expired])
            order.removeFirst(expired)
        }
        return new
    }
}
