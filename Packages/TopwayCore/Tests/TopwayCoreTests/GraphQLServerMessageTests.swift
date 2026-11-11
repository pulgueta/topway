import Foundation
import Testing

@testable import TopwayCore

struct GraphQLServerMessageTests {
    private struct Payload: Decodable, Equatable {
        let value: Int
    }

    private func decode(_ text: String) throws -> GraphQLServerMessage<Payload> {
        try JSONDecoder().decode(GraphQLServerMessage<Payload>.self, from: Data(text.utf8))
    }

    @Test("connection_ack, ping and pong have no id")
    func controlMessages() throws {
        #expect(try decode(#"{"type":"connection_ack"}"#) == .connectionAck)
        #expect(try decode(#"{"type":"ping","payload":{}}"#) == .ping)
        #expect(try decode(#"{"type":"pong"}"#) == .pong)
    }

    @Test("next gives the id and the GraphQL data")
    func nextWithData() throws {
        let message = try decode(#"{"id":"1","type":"next","payload":{"data":{"value":7}}}"#)

        guard case .next(let id, let response) = message else {
            Issue.record("Unexpected message: \(message)")
            return
        }
        #expect(id == "1")
        #expect(response.data == Payload(value: 7))
        #expect(response.errors == nil)
    }

    @Test("next can hold GraphQL errors in place of data")
    func nextWithErrors() throws {
        let message = try decode(
            #"{"id":"1","type":"next","payload":{"errors":[{"message":"Problem processing request"}]}}"#
        )

        guard case .next(_, let response) = message else {
            Issue.record("Unexpected message: \(message)")
            return
        }
        #expect(response.data == nil)
        #expect(response.errors == [GraphQLError(message: "Problem processing request")])
    }

    @Test("error gives the id and the list of errors")
    func error() throws {
        let message = try decode(
            #"{"id":"1","type":"error","payload":[{"message":"Cannot query field","locations":[]}]}"#
        )

        #expect(message == .error(id: "1", [GraphQLError(message: "Cannot query field")]))
    }

    @Test("complete gives the id")
    func complete() throws {
        #expect(try decode(#"{"id":"1","type":"complete"}"#) == .complete(id: "1"))
    }

    @Test("An unknown type is a decoding error")
    func unknownType() {
        #expect(throws: DecodingError.self) {
            try decode(#"{"type":"data"}"#)
        }
    }
}
