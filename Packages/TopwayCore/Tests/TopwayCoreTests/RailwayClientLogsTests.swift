import Foundation
import Testing
import TopwayCore

/// `StubURLProtocol` answers the socket upgrade and the queries with the same reply.
/// A reply that is not an upgrade makes the socket fail before it connects.
struct RailwayClientLogsTests {
    private static let twoLines = """
        {"data":{"lines":[
          {"timestamp":"2026-11-10T12:00:00.1Z","message":"Starting","severity":"info"},
          {"timestamp":"2026-11-10T12:00:00.2Z","message":"Disk low","severity":"warn"}
        ]}}
        """

    private struct Result {
        var events: [LogEvent] = []
        var error: (any Error)?
        let server: StubServer
        let sleep: StubSleep
    }

    private func stream(_ kind: LogKind, reply: StubReply, stopAt: Int = 3) async -> Result {
        let server = StubServer(reply)
        let sleep = StubSleep(stopAt: stopAt)
        let client = RailwayClient(session: server.session, sleep: sleep.sleep)
        var result = Result(server: server, sleep: sleep)
        do {
            for try await event in client.logs(kind, deploymentId: "d1", token: "secret") {
                result.events.append(event)
            }
        } catch {
            result.error = error
        }
        return result
    }

    @Test("When the socket cannot connect, the client polls and gives each line once")
    func pollingWithoutDuplicates() async throws {
        let result = await stream(.deploy, reply: StubReply(body: Self.twoLines))

        #expect(
            result.events == [
                .connection(.polling),
                .lines([
                    LogLine(
                        timestamp: "2026-11-10T12:00:00.1Z", message: "Starting", severity: "info"),
                    LogLine(
                        timestamp: "2026-11-10T12:00:00.2Z", message: "Disk low", severity: "warn"),
                ]),
            ])
        #expect(result.error == nil)
        // One upgrade request, then three polls with the same two lines.
        let polls = result.server.requests.dropFirst()
        #expect(polls.count == 3)
        #expect(result.sleep.durations == [.seconds(5), .seconds(5), .seconds(5)])
        for poll in polls {
            #expect(poll.method == "POST")
            #expect(poll.variables == ["deploymentId": "d1"])
            #expect(poll.query?.contains("deploymentLogs(") == true)
        }
    }

    @Test("Build logs use the build log query")
    func buildLogs() async throws {
        let result = await stream(.build, reply: StubReply(body: Self.twoLines), stopAt: 1)

        let poll = try #require(result.server.requests.last)
        #expect(poll.query?.contains("buildLogs(") == true)
        #expect(poll.query?.contains("deploymentLogs(") == false)
    }

    @Test("A failed poll stops the stream with the error")
    func failedPoll() async throws {
        let result = await stream(.deploy, reply: StubReply(status: 500, body: ""))

        #expect(result.events == [.connection(.polling)])
        guard case .httpStatus(500, _) = try #require(result.error as? RailwayError) else {
            Issue.record("Unexpected error: \(String(describing: result.error))")
            return
        }
    }

    @Test("A refused token stops the stream, with no polling")
    func refusedToken() async throws {
        let result = await stream(.deploy, reply: StubReply(status: 401, body: ""))

        #expect(result.events.isEmpty)
        #expect(result.server.requests.count == 1)
        guard case .unauthorized = try #require(result.error as? RailwayError) else {
            Issue.record("Unexpected error: \(String(describing: result.error))")
            return
        }
    }
}
