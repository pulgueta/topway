import Foundation
import Testing

@testable import TopwayCore

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

    @Test("Projects give the latest deployment status of each service in each environment")
    func latestDeploymentStatuses() async throws {
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"workspace":{"projects":{"edges":[
                      {"node":{"id":"p1","name":"shop","deletedAt":null,
                       "services":{"edges":[{"node":{"id":"s1","name":"web"}}]},
                       "environments":{"edges":[
                         {"node":{"id":"e1","name":"production","serviceInstances":{"edges":[
                           {"node":{"serviceId":"s1","latestDeployment":{"id":"d1",
                             "status":"CRASHED","staticUrl":null,
                             "createdAt":"2026-11-10T10:00:00Z"}}}]}}},
                         {"node":{"id":"e2","name":"staging","serviceInstances":{"edges":[
                           {"node":{"serviceId":"s1","latestDeployment":null}}]}}}
                       ]}}}
                    ]}}}}
                    """))

        let projects = try await RailwayClient(session: server.session)
            .fetchProjects(workspaceId: "w1", token: "secret")

        #expect(
            projects.flatMap(\.serviceStatuses) == [
                ServiceStatus(
                    projectId: "p1", projectName: "shop", environmentId: "e1",
                    environmentName: "production", serviceId: "s1", serviceName: "web",
                    deploymentId: "d1", status: "CRASHED")
            ])
        let query = try #require(server.requests.first?.query)
        #expect(query.contains("latestDeployment"))
    }

    @Test("Deleted environments and deleted service instances give no status")
    func deletedEnvironmentsAndInstances() async throws {
        let deployment =
            #"{"id":"d1","status":"FAILED","staticUrl":null,"createdAt":"2026-11-10T10:00:00Z"}"#
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"workspace":{"projects":{"edges":[
                      {"node":{"id":"p1","name":"shop","deletedAt":null,
                       "services":{"edges":[{"node":{"id":"s1","name":"web"}},
                         {"node":{"id":"s2","name":"api"}}]},
                       "environments":{"edges":[
                         {"node":{"id":"e1","name":"production","deletedAt":null,
                           "serviceInstances":{"edges":[
                             {"node":{"serviceId":"s1","deletedAt":null,
                               "latestDeployment":\(deployment)}},
                             {"node":{"serviceId":"s2","deletedAt":"2026-11-09T00:00:00Z",
                               "latestDeployment":\(deployment)}}]}}},
                         {"node":{"id":"e2","name":"pr-12","deletedAt":"2026-11-09T00:00:00Z",
                           "serviceInstances":{"edges":[
                             {"node":{"serviceId":"s1","deletedAt":null,
                               "latestDeployment":\(deployment)}}]}}}
                       ]}}}
                    ]}}}}
                    """))

        let projects = try await RailwayClient(session: server.session)
            .fetchProjects(workspaceId: "w1", token: "secret")

        #expect(projects.flatMap(\.serviceStatuses).map(\.environmentId) == ["e1"])
        #expect(projects.flatMap(\.serviceStatuses).map(\.serviceId) == ["s1"])
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
