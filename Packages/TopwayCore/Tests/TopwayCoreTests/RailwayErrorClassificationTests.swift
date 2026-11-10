import Foundation
import Testing
import TopwayCore

struct RailwayErrorClassificationTests {
    @Test("CancellationError is a cancellation")
    func cancellationError() {
        guard case .cancelled = RailwayError(transportFailure: CancellationError()) else {
            Issue.record("Expected .cancelled")
            return
        }
    }

    @Test("URLError.cancelled is a cancellation")
    func cancelledURLError() {
        guard case .cancelled = RailwayError(transportFailure: URLError(.cancelled)) else {
            Issue.record("Expected .cancelled")
            return
        }
    }

    @Test("Other transport failures are network errors")
    func otherFailure() {
        guard case .networkError = RailwayError(transportFailure: URLError(.timedOut)) else {
            Issue.record("Expected .networkError")
            return
        }
    }

    @Test("A cancellation has no message for the user")
    func cancellationHasNoMessage() {
        #expect(RailwayError.cancelled.errorDescription == nil)
    }

    @Test("A cancelled request gives a cancellation from the client")
    func clientCancelledRequest() async throws {
        let server = StubServer(StubReply(body: "", failure: URLError(.cancelled)))
        let client = RailwayClient(session: server.session)

        let error = await #expect(throws: RailwayError.self) {
            _ = try await client.deleteProject(projectId: "p1", token: "secret")
        }

        guard case .cancelled = try #require(error) else {
            Issue.record("Unexpected error: \(String(describing: error))")
            return
        }
    }

    @Test("A connection failure stays a network error in the client")
    func clientConnectionFailure() async throws {
        let server = StubServer(StubReply(body: "", failure: URLError(.notConnectedToInternet)))
        let client = RailwayClient(session: server.session)

        let error = await #expect(throws: RailwayError.self) {
            _ = try await client.deleteProject(projectId: "p1", token: "secret")
        }

        guard case .networkError = try #require(error) else {
            Issue.record("Unexpected error: \(String(describing: error))")
            return
        }
    }
}
