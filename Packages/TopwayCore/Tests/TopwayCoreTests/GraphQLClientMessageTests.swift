import Testing

@testable import TopwayCore

struct GraphQLClientMessageTests {
    @Test("connection_init has only a type, because Railway reads the token from the header")
    func connectionInit() {
        #expect(GraphQLClientMessage.connectionInit.text == #"{"type":"connection_init"}"#)
    }

    @Test("subscribe sends the id, the query and the variables")
    func subscribe() {
        let request = GraphQLRequest(
            query: "subscription { a/b }", variables: ["deploymentId": "d1"])

        #expect(
            GraphQLClientMessage.subscribe(id: "1", request).text
                == #"{"id":"1","payload":{"query":"subscription { a/b }","variables":{"deploymentId":"d1"}},"type":"subscribe"}"#
        )
    }

    @Test("complete names the operation to stop")
    func complete() {
        #expect(GraphQLClientMessage.complete(id: "1").text == #"{"id":"1","type":"complete"}"#)
    }

    @Test("ping checks that the server still answers")
    func ping() {
        #expect(GraphQLClientMessage.ping.text == #"{"type":"ping"}"#)
    }

    @Test("pong answers a ping")
    func pong() {
        #expect(GraphQLClientMessage.pong.text == #"{"type":"pong"}"#)
    }
}
