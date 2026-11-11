import Foundation
import Testing

@testable import TopwayCore

struct SampleDataSourceLogsTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    private func events(_ kind: LogKind, stopAt: Int = 3) async throws -> ([LogEvent], StubSleep) {
        let sleep = StubSleep(stopAt: stopAt)
        let source = SampleDataSource(now: { [now] in now }, sleep: sleep.sleep)
        var events: [LogEvent] = []
        for try await event in source.logs(kind, deploymentId: "deployment-1", token: "") {
            events.append(event)
        }
        return (events, sleep)
    }

    private func lines(in events: [LogEvent]) -> [[LogLine]] {
        events.compactMap {
            guard case .lines(let lines) = $0 else { return nil }
            return lines
        }
    }

    @Test("Deploy logs are live, start with all levels, then add one line at each tick")
    func deployLogs() async throws {
        let (events, sleep) = try await events(.deploy)

        #expect(events.first == .connection(.live))
        let batches = lines(in: events)
        // The start lines, then one line after each of the two ticks before the stop.
        #expect(batches.map(\.count) == [6, 1, 1])
        #expect(Set(batches[0].map(\.level)) == [.info, .warning, .error])
        #expect(batches[0].last?.timestamp == "2026-11-10T11:59:59Z")
        #expect(batches[1].first?.timestamp == "2026-11-10T12:00:01Z")
        #expect(batches[2].first?.timestamp == "2026-11-10T12:00:02Z")
        #expect(sleep.durations == [.seconds(2), .seconds(2), .seconds(2)])
    }

    @Test("The same date gives the same lines")
    func deterministic() async throws {
        let first = try await events(.deploy)
        let second = try await events(.deploy)

        #expect(first.0 == second.0)
    }

    @Test("Build logs are live, give the build steps one time, then end")
    func buildLogs() async throws {
        let (events, sleep) = try await events(.build)

        #expect(events.first == .connection(.live))
        let batches = lines(in: events)
        #expect(batches.count == 1)
        let build = try #require(batches.first)
        #expect(build.first?.message == "Using Nixpacks")
        #expect(build.contains { $0.level == .warning })
        #expect(sleep.durations.isEmpty)
    }
}
