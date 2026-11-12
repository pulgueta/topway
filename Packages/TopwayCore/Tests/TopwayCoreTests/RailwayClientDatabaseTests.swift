import Foundation
import Testing

@testable import TopwayCore

struct RailwayClientDatabaseTests {
    private let template = StubReply(
        body: """
            {"data":{"template":{"id":"t1","serializedConfig":{"services":{"s1":{
              "name":"Redis","variables":{"REDISPORT":{"defaultValue":"6379"}}}}}}}}
            """)
    private let deploy = StubReply(
        body: #"{"data":{"templateDeployV2":{"projectId":"p1","workflowId":"w1"}}}"#)

    private func status(_ status: String, error: String = "null") -> StubReply {
        StubReply(body: #"{"data":{"workflowStatus":{"status":"\#(status)","error":\#(error)}}}"#)
    }

    private func run(_ server: StubServer, sleep: StubSleep = StubSleep(stopAt: .max))
        async throws -> Bool
    {
        try await RailwayClient(session: server.session, sleep: sleep.sleep).deployDatabase(
            .redis, projectId: "p1", environmentId: "e1", token: "secret")
    }

    @Test("Deploy reads the template with no token, sends its filled configuration, then waits")
    func deployAndWait() async throws {
        let server = StubServer(template, deploy, status("Running"), status("Complete"))
        let sleep = StubSleep(stopAt: .max)

        let isComplete = try await run(server, sleep: sleep)

        #expect(isComplete)
        let requests = server.requests
        try #require(requests.count == 4)
        #expect(requests[0].authorization == nil)
        #expect(requests[0].variables == ["code": "redis"])
        #expect(requests[1].authorization == "Bearer secret")
        #expect(
            requests[1].variablesJSON
                == #"{"environmentId":"e1","projectId":"p1","serializedConfig":{"services":{"s1":{"name":"Redis","variables":{"REDISPORT":{"defaultValue":"6379","value":"6379"}}}}},"templateId":"t1"}"#
        )
        #expect(try #require(requests[1].query).contains("templateDeployV2"))
        #expect(requests[2].variables == ["workflowId": "w1"])
        #expect(requests[3].authorization == "Bearer secret")
        // One wait before each status request.
        #expect(sleep.durations == [.seconds(2), .seconds(2)])
    }

    @Test("With no workflow, the deploy is complete at once")
    func noWorkflow() async throws {
        let server = StubServer(
            template, StubReply(body: #"{"data":{"templateDeployV2":{"projectId":"p1"}}}"#))

        #expect(try await run(server))
        #expect(server.requests.count == 2)
    }

    @Test("A workflow error is the error of the deploy")
    func workflowError() async throws {
        let server = StubServer(template, deploy, status("Error", error: #""no capacity""#))

        let error = await #expect(throws: RailwayError.self) {
            _ = try await run(server)
        }
        #expect(error?.errorDescription == "Railway sent an error: no capacity")
        #expect(server.requests.count == 3)
    }

    @Test("A workflow that runs for 60 seconds gives false, and Topway stops the wait")
    func timeout() async throws {
        let server = StubServer(template, deploy, status("Running"))
        let sleep = StubSleep(stopAt: .max)

        let isComplete = try await run(server, sleep: sleep)

        #expect(!isComplete)
        #expect(sleep.durations.count == 30)
        #expect(server.requests.count == 32)
    }

    @Test("A template with no configuration sends no deploy request")
    func noConfiguration() async throws {
        let server = StubServer(
            StubReply(body: #"{"data":{"template":{"id":"t1","serializedConfig":null}}}"#))

        await #expect(throws: TemplateConfigProblem.noConfiguration) {
            _ = try await run(server)
        }
        #expect(server.requests.count == 1)
    }
}
