import Testing
import TopwayCore

struct LogBufferTests {
    private func line(_ number: Int) -> LogLine {
        LogLine(timestamp: "2026-11-10T12:00:\(number)Z", message: "line \(number)", severity: nil)
    }

    @Test("Lines keep their order and get increasing IDs")
    func append() {
        var buffer = LogBuffer()

        buffer.append([line(1), line(2)])
        buffer.append([line(3)])

        #expect(buffer.entries.map(\.line) == [line(1), line(2), line(3)])
        #expect(buffer.entries.map(\.id) == [0, 1, 2])
    }

    @Test("The buffer keeps the newest 1,000 lines, and each line keeps its ID")
    func capacity() {
        var buffer = LogBuffer()

        buffer.append((1...1_001).map(line))
        buffer.append([line(1_002)])

        #expect(LogBuffer.capacity == 1_000)
        #expect(buffer.entries.count == 1_000)
        #expect(buffer.entries.first?.line == line(3))
        #expect(buffer.entries.first?.id == 2)
        #expect(buffer.entries.last?.id == 1_001)
    }

    @Test("The copy text has one line for each entry, with its timestamp")
    func text() {
        var buffer = LogBuffer()
        buffer.append([line(1), line(2)])

        #expect(buffer.text == "2026-11-10T12:00:1Z line 1\n2026-11-10T12:00:2Z line 2")
    }

}
