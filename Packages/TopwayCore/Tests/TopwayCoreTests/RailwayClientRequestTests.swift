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

    @Test("Projects that Railway marked as deleted do not appear")
    func deletedProjectsAreFiltered() async throws {
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"workspace":{"projects":{"edges":[
                      {"node":{"id":"p1","name":"Live","deletedAt":null,
                       "services":{"edges":[]},"environments":{"edges":[]}}},
                      {"node":{"id":"p2","name":"Gone","deletedAt":"2026-06-01T00:00:00Z",
                       "services":{"edges":[]},"environments":{"edges":[]}}}
                    ]}}}}
                    """))

        let projects = try await RailwayClient(session: server.session)
            .fetchProjects(workspaceId: "w1", token: "secret")

        #expect(projects.map(\.name) == ["Live"])
        let request = try #require(server.requests.first)
        let query = try #require(request.query)
        #expect(query.contains("deletedAt"))
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
        let variables = try #require(request.variables)
        let query = try #require(request.query)
        #expect(variables == expected)
        #expect(!query.contains(input))
        #expect(!query.contains("\""))
    }
}
