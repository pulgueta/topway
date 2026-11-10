import Foundation
import Testing
import TopwayCore

struct RailwayClientRequestTests {
    @Test("Each request goes to the railway.com endpoint with a bearer token")
    func endpointAndToken() async throws {
        let server = StubServer(StubReply(body: #"{"data":{"projectDelete":true}}"#))

        _ = try await RailwayClient(session: server.session)
            .deleteProject(projectId: "p1", token: "secret")

        let request = try #require(server.requests.first)
        #expect(request.url?.absoluteString == "https://backboard.railway.com/graphql/v2")
        #expect(request.method == "POST")
        #expect(request.authorization == "Bearer secret")
    }

    @Test(
        "User input reaches the request JSON unchanged, and only through variables",
        arguments: ClientCall.all,
        [
            #"C:\new\table"#,
            #"say "hello""#,
            "line one\nline two",
            "${{ Service.VAR }}",
            #"\"mixed\\"#,
        ])
    func inputTravelsThroughVariables(call: ClientCall, input: String) async throws {
        let server = StubServer(StubReply(body: call.reply))

        try await call.run(RailwayClient(session: server.session), input)

        let request = try #require(server.requests.first)
        let expected = Dictionary(uniqueKeysWithValues: call.variableNames.map { ($0, input) })
        #expect(request.variables == expected)
        #expect(!request.query.contains(input))
        #expect(!request.query.contains("\""))
    }
}
