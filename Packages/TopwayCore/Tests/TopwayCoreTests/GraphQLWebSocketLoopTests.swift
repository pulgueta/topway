import Foundation
import Testing

@testable import TopwayCore

/// Drives the socket loop through `ScriptedTransport`, with no network.
struct GraphQLWebSocketLoopTests {
    private struct Payload: Decodable, Sendable, Equatable {
        let value: Int
    }

    private static let request = GraphQLRequest(query: "subscription { value }", variables: [:])
    private static let ack = ScriptedTransport.Frame.text(#"{"type":"connection_ack"}"#)
    private static let complete = ScriptedTransport.Frame.text(#"{"id":"1","type":"complete"}"#)

    private static func next(_ value: Int) -> ScriptedTransport.Frame {
        .text(#"{"id":"1","type":"next","payload":{"data":{"value":\#(value)}}}"#)
    }

    /// The keepalive waits until the test ends, so it does not act.
    private static let idleSleep: @Sendable (Duration) async throws -> Void = { _ in
        try await Task.sleep(for: .seconds(3_600))
    }

    private func socket(
        _ transport: ScriptedTransport,
        sleep: @escaping @Sendable (Duration) async throws -> Void = idleSleep
    ) -> GraphQLWebSocket {
        GraphQLWebSocket(connect: { _ in transport }, sleep: sleep)
    }

    @Test("The loop sends init, subscribes after the ack, gives payloads and ends on complete")
    func fullExchange() async throws {
        let transport = ScriptedTransport([Self.ack, Self.next(1), Self.next(2), Self.complete])

        var events: [SubscriptionEvent<Payload>] = []
        for try await event in socket(transport).subscribe(
            Self.request, token: "secret", as: Payload.self)
        {
            events.append(event)
        }

        #expect(events == [.connected, .payload(Payload(value: 1)), .payload(Payload(value: 2))])
        #expect(
            transport.sent == [
                GraphQLClientMessage.connectionInit.text,
                GraphQLClientMessage.subscribe(id: "1", Self.request).text,
            ])
        #expect(await transport.waitForClose() == 1_000)
    }

    @Test("A ping from the server gets a pong")
    func pingGetsPong() async throws {
        let transport = ScriptedTransport([Self.ack, .text(#"{"type":"ping"}"#), Self.complete])

        for try await _ in socket(transport).subscribe(
            Self.request, token: "secret", as: Payload.self)
        {}

        #expect(transport.sent.last == GraphQLClientMessage.pong.text)
    }

    @Test("When the consumer stops, the client sends complete and closes the transport")
    func cancelSendsComplete() async throws {
        let transport = ScriptedTransport([Self.ack])

        for try await event in socket(transport).subscribe(
            Self.request, token: "secret", as: Payload.self)
        {
            #expect(event == .connected)
            break
        }

        #expect(await transport.waitForClose() == 1_000)
        #expect(transport.sent.last == GraphQLClientMessage.complete(id: "1").text)
    }

    @Test("A transport failure after the ack is a network error")
    func failureAfterAck() async throws {
        let transport = ScriptedTransport([Self.ack, .failure(URLError(.networkConnectionLost))])

        let error = await #expect(throws: RailwayError.self) {
            for try await _ in socket(transport).subscribe(
                Self.request, token: "secret", as: Payload.self)
            {}
        }

        guard case .networkError = try #require(error) else {
            Issue.record("Unexpected error: \(String(describing: error))")
            return
        }
    }

    @Test("With no answer to a ping, the keepalive drops the socket as a network error")
    func keepaliveDrop() async throws {
        let transport = ScriptedTransport([Self.ack])
        let sleep = StubSleep(stopAt: 100)

        let error = await #expect(throws: RailwayError.self) {
            for try await _ in socket(transport, sleep: sleep.sleep).subscribe(
                Self.request, token: "secret", as: Payload.self)
            {}
        }

        guard case .networkError = try #require(error) else {
            Issue.record("Unexpected error: \(String(describing: error))")
            return
        }
        #expect(transport.sent.contains(GraphQLClientMessage.ping.text))
        #expect(transport.closeCode == 1_001)
    }
}
