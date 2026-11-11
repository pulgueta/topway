import Foundation
import Testing

@testable import TopwayCore

/// Drives `RailwayClient.logs` with scripted sockets. `StubURLProtocol` answers the polls.
struct RailwayClientRecoveryTests {
    static let ack = ScriptedTransport.Frame.text(#"{"type":"connection_ack"}"#)
    static let lines = """
        {"data":{"lines":[{"timestamp":"2026-11-10T12:00:00Z","message":"Ready","severity":"info"}]}}
        """

    struct Result {
        var events: [LogEvent] = []
        var error: (any Error)?
    }

    static func stream(
        _ connector: ScriptedConnector, poll reply: StubReply, sleep: StubSleep
    ) async -> (Result, StubServer) {
        let server = StubServer(reply)
        let client = RailwayClient(
            session: server.session, sleep: sleep.sleep, socket: connector.socket)
        var result = Result()
        do {
            for try await event in client.logs(.deploy, deploymentId: "d1", token: "secret") {
                result.events.append(event)
            }
        } catch {
            result.error = error
        }
        return (result, server)
    }

    @Test("A socket that acks and then fails each time does not reconnect forever")
    func ackThenFailEachTime() async throws {
        let connector = ScriptedConnector { _ in
            ScriptedTransport([Self.ack, .failure(URLError(.networkConnectionLost))])
        }

        let (result, server) = await Self.stream(
            connector, poll: StubReply(body: Self.lines), sleep: StubSleep(stopAt: 3))

        #expect(connector.connects == 3)
        #expect(result.events.contains(.connection(.polling)))
        #expect(!server.requests.isEmpty)
        #expect(result.error == nil)
    }

    @Test("A socket that acks and then sends bad data each time stops with the error")
    func ackThenBadDataEachTime() async throws {
        let connector = ScriptedConnector { _ in
            ScriptedTransport([Self.ack, .text("not a message")])
        }

        let (result, server) = await Self.stream(
            connector, poll: StubReply(body: Self.lines), sleep: StubSleep(stopAt: 100))

        #expect(connector.connects == 3)
        #expect(server.requests.isEmpty)
        guard case .decodingError = try #require(result.error as? RailwayError) else {
            Issue.record("Unexpected error: \(String(describing: result.error))")
            return
        }
    }

    @Test("The live socket accepts messages up to 16 MiB")
    func maximumMessageSize() async throws {
        let server = StubServer(StubReply(status: 401, body: ""))
        let transport = GraphQLWebSocket.liveTransport(
            session: server.session,
            request: URLRequest(url: try #require(URL(string: "wss://example.com"))))
        defer { transport.close(code: 1_000) }

        #expect(transport.task.maximumMessageSize == 16 * 1_024 * 1_024)
    }

    static let complete = ScriptedTransport.Frame.text(#"{"id":"1","type":"complete"}"#)
    static let next = ScriptedTransport.Frame.text(
        #"{"id":"1","type":"next","payload":{"data":{"lines":[{"timestamp":"t1","message":"Ready","severity":"info"}]}}}"#
    )

    @Test("A drop, then a failed reconnect, does not stop the stream")
    func dropThenFailedReconnect() async throws {
        let connector = ScriptedConnector { connect in
            switch connect {
            case 1:
                ScriptedTransport([Self.ack, Self.next, .failure(URLError(.networkConnectionLost))])
            case 2: ScriptedTransport([.failure(URLError(.cannotConnectToHost))])
            default: ScriptedTransport([Self.ack, Self.complete])
            }
        }
        let sleep = StubSleep(stopAt: 100)

        let (result, server) = await Self.stream(
            connector, poll: StubReply(body: Self.lines), sleep: sleep)

        #expect(connector.connects == 3)
        #expect(result.error == nil)
        #expect(result.events.filter { $0 == .connection(.live) }.count == 2)
        #expect(sleep.durations == [.seconds(2), .seconds(4)])
        #expect(server.requests.isEmpty)
    }

    @Test("Polling tries the socket again after 60 seconds, and goes back to live")
    func pollingRecoversToSocket() async throws {
        let connector = ScriptedConnector { connect in
            connect == 1
                ? ScriptedTransport([.failure(URLError(.cannotConnectToHost))])
                : ScriptedTransport([Self.ack, Self.complete])
        }
        let sleep = StubSleep(stopAt: 100)

        let (result, server) = await Self.stream(
            connector, poll: StubReply(body: Self.lines), sleep: sleep)

        #expect(connector.connects == 2)
        #expect(server.requests.count == 12)
        #expect(sleep.durations == Array(repeating: .seconds(5), count: 12))
        #expect(result.events.first == .connection(.polling))
        #expect(result.events.last == .connection(.live))
        #expect(result.error == nil)
    }

    @Test("A network error in polling does not stop the stream")
    func networkErrorInPolling() async throws {
        let connector = ScriptedConnector { _ in
            ScriptedTransport([.failure(URLError(.cannotConnectToHost))])
        }

        let (result, server) = await Self.stream(
            connector, poll: StubReply(body: "", failure: URLError(.notConnectedToInternet)),
            sleep: StubSleep(stopAt: 3))

        #expect(server.requests.count == 3)
        #expect(result.events == [.connection(.polling)])
        #expect(result.error == nil)
    }

    @Test("A server complete ends the stream, with no polling")
    func completeEndsStream() async throws {
        let connector = ScriptedConnector { _ in
            ScriptedTransport([Self.ack, Self.next, Self.complete])
        }

        let (result, server) = await Self.stream(
            connector, poll: StubReply(body: Self.lines), sleep: StubSleep(stopAt: 100))

        #expect(result.error == nil)
        #expect(server.requests.isEmpty)
    }

    @Test(
        "Polling a build log ends when the build is finished, and continues while it runs",
        arguments: [("SUCCESS", 1), ("FAILED", 1), ("BUILDING", 3), ("QUEUED", 3)])
    func buildLogEnds(status: String, polls: Int) async throws {
        let connector = ScriptedConnector { _ in
            ScriptedTransport([.failure(URLError(.cannotConnectToHost))])
        }
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"lines":[],"deployment":{"id":"d1","status":"\(status)",\
                    "staticUrl":null,"createdAt":"2026-11-10T12:00:00Z"}}}
                    """))
        let client = RailwayClient(
            session: server.session, sleep: StubSleep(stopAt: 3).sleep, socket: connector.socket)

        var events: [LogEvent] = []
        for try await event in client.logs(.build, deploymentId: "d1", token: "secret") {
            events.append(event)
        }

        #expect(server.requests.count == polls)
        #expect(events == [.connection(.polling)])
        let query = try #require(server.requests.first?.query)
        #expect(query.contains("deployment(id: $deploymentId)"))
    }
}
