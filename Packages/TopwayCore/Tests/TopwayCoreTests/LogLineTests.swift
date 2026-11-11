import Foundation
import Testing
import TopwayCore

struct LogLineTests {
    @Test("A Railway log decodes with its timestamp, message and severity")
    func decode() throws {
        let json = """
            {"timestamp":"2026-11-10T12:00:00.123456789Z","message":"Ready","severity":"info"}
            """

        let line = try JSONDecoder().decode(LogLine.self, from: Data(json.utf8))

        #expect(line.timestamp == "2026-11-10T12:00:00.123456789Z")
        #expect(line.message == "Ready")
        #expect(line.level == .info)
    }

    @Test(
        "The severity gives the level",
        arguments: [
            ("info", .info), ("debug", .info), (nil, .info), ("WARN", .warning),
            ("warning", .warning), ("err", .error), ("error", .error), ("fatal", .error),
        ] as [(String?, LogLevel)])
    func level(severity: String?, level: LogLevel) {
        let line = LogLine(timestamp: "t", message: "m", severity: severity)

        #expect(line.level == level)
    }
}
