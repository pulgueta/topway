import Foundation
import Testing

@testable import TopwayCore

struct GraphQLSubscriptionTests {
    private struct Payload: Decodable, Equatable {
        let value: Int
    }

    private let request = GraphQLRequest(query: "subscription { value }", variables: [:])

    private func makeSubscription() -> GraphQLSubscription<Payload> {
        GraphQLSubscription(id: "1", request: request)
    }

    private func acknowledged() throws -> GraphQLSubscription<Payload> {
        var subscription = makeSubscription()
        _ = try subscription.receive(#"{"type":"connection_ack"}"#)
        return subscription
    }

    private func receiveError(
        _ text: String, in subscription: GraphQLSubscription<Payload>
    ) -> RailwayError? {
        var subscription = subscription
        do {
            let step = try subscription.receive(text)
            Issue.record("Expected an error, got \(step)")
            return nil
        } catch {
            return error
        }
    }

    @Test("The acknowledgement connects and sends the subscription")
    func acknowledgement() throws {
        var subscription = makeSubscription()

        let step = try subscription.receive(#"{"type":"connection_ack"}"#)

        #expect(step == .connected(send: .subscribe(id: "1", request)))
    }

    @Test(
        "An operation message before the acknowledgement is an error",
        arguments: [
            #"{"id":"1","type":"next","payload":{"data":{"value":1}}}"#,
            #"{"id":"1","type":"complete"}"#,
        ])
    func operationBeforeAcknowledgement(text: String) throws {
        let error = try #require(receiveError(text, in: makeSubscription()))

        guard case .unknown = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
    }

    @Test("A ping gets a pong, also before the acknowledgement")
    func ping() throws {
        var subscription = makeSubscription()

        #expect(try subscription.receive(#"{"type":"ping"}"#) == .reply(.pong))
    }

    @Test("A pong needs no action")
    func pong() throws {
        var subscription = try acknowledged()

        #expect(try subscription.receive(#"{"type":"pong"}"#) == .ignore)
    }

    @Test("next with data gives the payload")
    func nextWithData() throws {
        var subscription = try acknowledged()

        let step = try subscription.receive(
            #"{"id":"1","type":"next","payload":{"data":{"value":3}}}"#)

        #expect(step == .payload(Payload(value: 3)))
    }

    @Test("Messages for another operation id need no action")
    func otherOperation() throws {
        var subscription = try acknowledged()

        #expect(
            try subscription.receive(#"{"id":"2","type":"next","payload":{"data":{"value":3}}}"#)
                == .ignore)
        #expect(try subscription.receive(#"{"id":"2","type":"complete"}"#) == .ignore)
    }

    @Test("complete ends the subscription")
    func complete() throws {
        var subscription = try acknowledged()

        #expect(try subscription.receive(#"{"id":"1","type":"complete"}"#) == .completed)
    }

    @Test("next with GraphQL errors is a GraphQL error")
    func nextWithErrors() throws {
        let error = try #require(
            receiveError(
                #"{"id":"1","type":"next","payload":{"errors":[{"message":"A"},{"message":"B"}]}}"#,
                in: try acknowledged()))

        guard case .graphQLError(let message) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(message == "A, B")
    }

    @Test("An error message is a GraphQL error")
    func errorMessage() throws {
        let error = try #require(
            receiveError(
                #"{"id":"1","type":"error","payload":[{"message":"Cannot query field"}]}"#,
                in: try acknowledged()))

        guard case .graphQLError(let message) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(message == "Cannot query field")
    }

    @Test(
        "A Not Authorized message is the same error as an HTTP 401",
        arguments: [
            #"{"id":"1","type":"error","payload":[{"message":"Not Authorized"}]}"#,
            #"{"id":"1","type":"next","payload":{"errors":[{"message":"Not Authorized"}]}}"#,
        ])
    func notAuthorized(text: String) throws {
        let error = try #require(receiveError(text, in: try acknowledged()))

        guard case .unauthorized = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
    }

    @Test("Text that is not a protocol message is a decoding error")
    func notAMessage() throws {
        let error = try #require(receiveError("hello", in: try acknowledged()))

        guard case .decodingError = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
    }

    @Test(
        "A refused upgrade or an auth close code is the same error as an HTTP 401",
        arguments: [(1006, 401), (4401, 101), (4403, 101)])
    func authFailure(closeCode: Int, httpStatus: Int) {
        let error = GraphQLSubscription<Payload>.error(
            for: URLError(.badServerResponse), closeCode: closeCode, httpStatus: httpStatus)

        guard case .unauthorized = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
    }

    @Test("Other socket failures are network errors")
    func networkFailure() {
        let error = GraphQLSubscription<Payload>.error(
            for: URLError(.networkConnectionLost), closeCode: 1006, httpStatus: 101)

        guard case .networkError = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
    }

    @Test("A protocol error keeps its type")
    func protocolErrorIsKept() {
        let error = GraphQLSubscription<Payload>.error(
            for: RailwayError.graphQLError("A"), closeCode: 1000, httpStatus: 101)

        guard case .graphQLError("A") = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
    }
}
