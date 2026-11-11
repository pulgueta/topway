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
}
