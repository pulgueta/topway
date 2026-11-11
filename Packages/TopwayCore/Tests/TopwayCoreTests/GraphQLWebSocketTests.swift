import Foundation
import Testing

@testable import TopwayCore

/// `StubURLProtocol` answers the upgrade request, so these tests use no network.
struct GraphQLWebSocketTests {
    private struct Payload: Decodable, Sendable {
        let value: Int
    }

    private func subscribe(_ reply: StubReply) async -> (RailwayError?, StubServer) {
        let server = StubServer(reply)
        let socket = GraphQLWebSocket(session: server.session)
        let stream = socket.subscribe(
            GraphQLRequest(query: "subscription { value }", variables: [:]),
            token: "secret", as: Payload.self)
        let error = await #expect(throws: RailwayError.self) {
            for try await _ in stream {}
        }
        return (error, server)
    }

    @Test("The upgrade request goes to the Railway socket with a bearer token")
    func upgradeRequest() async throws {
        let (_, server) = await subscribe(StubReply(status: 401, body: ""))

        let request = try #require(server.requests.first)
        #expect(request.url?.absoluteString == "wss://backboard.railway.com/graphql/v2")
        #expect(request.authorization == "Bearer secret")
    }

    @Test("A refused upgrade with status 401 is an unauthorized error")
    func refusedUpgrade() async throws {
        let (error, _) = await subscribe(StubReply(status: 401, body: ""))

        guard case .unauthorized = try #require(error) else {
            Issue.record("Unexpected error: \(String(describing: error))")
            return
        }
    }

    @Test("A server that does not upgrade is a network error")
    func noUpgrade() async throws {
        let (error, _) = await subscribe(StubReply(body: "{}"))

        guard case .networkError = try #require(error) else {
            Issue.record("Unexpected error: \(String(describing: error))")
            return
        }
    }
}
