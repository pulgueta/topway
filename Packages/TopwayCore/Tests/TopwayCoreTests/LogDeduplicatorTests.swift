import Testing

@testable import TopwayCore

struct LogDeduplicatorTests {
    private func line(_ message: String, at timestamp: String = "2026-11-10T12:00:00Z") -> LogLine {
        LogLine(timestamp: timestamp, message: message, severity: nil)
    }

    @Test("A replayed batch gives only the lines that were not seen, in their order")
    func replay() {
        var deduplicator = LogDeduplicator(capacity: 10)

        #expect(deduplicator.newLines(in: [line("a"), line("b")]) == [line("a"), line("b")])
        #expect(
            deduplicator.newLines(in: [line("a"), line("b"), line("c"), line("d")])
                == [line("c"), line("d")])
    }

    @Test("The same message at a different time is a new line")
    func sameMessageNewTime() {
        var deduplicator = LogDeduplicator(capacity: 10)
        _ = deduplicator.newLines(in: [line("tick", at: "2026-11-10T12:00:00Z")])

        let later = line("tick", at: "2026-11-10T12:00:01Z")
        #expect(deduplicator.newLines(in: [later]) == [later])
    }

    @Test("A repeat in one batch is removed")
    func repeatInBatch() {
        var deduplicator = LogDeduplicator(capacity: 10)

        #expect(deduplicator.newLines(in: [line("a"), line("a")]) == [line("a")])
    }

    @Test("Only the last lines up to the capacity are kept, so memory stays fixed")
    func capacity() {
        var deduplicator = LogDeduplicator(capacity: 2)
        _ = deduplicator.newLines(in: [line("a"), line("b"), line("c")])

        #expect(deduplicator.newLines(in: [line("a"), line("c")]) == [line("a")])
    }
}
