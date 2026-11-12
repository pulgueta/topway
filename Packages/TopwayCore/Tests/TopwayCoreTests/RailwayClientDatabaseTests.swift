import Foundation
import Synchronization
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

    private func wait(
        _ server: StubServer, sleep: StubSleep = StubSleep(stopAt: .max),
        now: @escaping @Sendable () -> Date = { Date(timeIntervalSince1970: 0) }
    ) async throws -> DatabaseDeployResult {
        try await RailwayClient(session: server.session, sleep: sleep.sleep, now: now)
            .waitForDatabase(workflowId: "w1", token: "secret")
    }

    @Test(
        "Deploy reads the template with no token, sends its filled configuration, and waits for nothing"
    )
    func deploy() async throws {
        let server = StubServer(template, deploy)

        let workflowId = try await RailwayClient(session: server.session).deployDatabase(
            .redis, projectId: "p1", environmentId: "e1", token: "secret")

        #expect(workflowId == "w1")
        let requests = server.requests
        try #require(requests.count == 2)
        #expect(requests[0].authorization == nil)
        #expect(requests[0].variables == ["code": "redis"])
        #expect(requests[1].authorization == "Bearer secret")
        #expect(
            requests[1].variablesJSON
                == #"{"environmentId":"e1","projectId":"p1","serializedConfig":{"services":{"s1":{"name":"Redis","variables":{"REDISPORT":{"defaultValue":"6379","value":"6379"}}}}},"templateId":"t1"}"#
        )
        #expect(try #require(requests[1].query).contains("templateDeployV2"))
    }

    @Test("With no workflow, the deploy gives no workflow ID")
    func noWorkflow() async throws {
        let server = StubServer(
            template, StubReply(body: #"{"data":{"templateDeployV2":{"projectId":"p1"}}}"#))

        let workflowId = try await RailwayClient(session: server.session).deployDatabase(
            .redis, projectId: "p1", environmentId: "e1", token: "secret")

        #expect(workflowId == nil)
    }

    @Test("A template with no configuration sends no deploy request")
    func noConfiguration() async throws {
        let server = StubServer(
            StubReply(body: #"{"data":{"template":{"id":"t1","serializedConfig":null}}}"#))

        await #expect(throws: TemplateConfigProblem.noConfiguration) {
            _ = try await RailwayClient(session: server.session).deployDatabase(
                .redis, projectId: "p1", environmentId: "e1", token: "secret")
        }
        #expect(server.requests.count == 1)
    }

    @Test("The wait asks for the status each 2 seconds, with a 10 second limit for each request")
    func waitUntilComplete() async throws {
        let server = StubServer(status("Running"), status("Complete"))
        let sleep = StubSleep(stopAt: .max)

        let result = try await wait(server, sleep: sleep)

        #expect(result == .complete)
        let requests = server.requests
        try #require(requests.count == 2)
        #expect(requests[0].variables == ["workflowId": "w1"])
        #expect(requests[0].authorization == "Bearer secret")
        #expect(requests.map(\.timeout) == [10, 10])
        #expect(sleep.durations == [.seconds(2), .seconds(2)])
    }

    @Test("A workflow error is the error of the deploy")
    func workflowError() async throws {
        let server = StubServer(status("Error", error: #""no capacity""#))

        let error = await #expect(throws: RailwayError.self) {
            _ = try await wait(server)
        }
        #expect(error?.errorDescription == "Railway sent an error: no capacity")
    }

    @Test(
        "A status request that fails is not a failed deploy: the database can show later",
        arguments: [
            StubReply(body: "", failure: URLError(.networkConnectionLost)),
            StubReply(body: #"{"errors":[{"message":"Problem processing request"}]}"#),
            StubReply(status: 502, body: "Bad Gateway"),
            StubReply(body: "not json"),
        ])
    func failedStatusRequest(reply: StubReply) async throws {
        let server = StubServer(status("Running"), reply)

        let result = try await wait(server)

        #expect(result == .pending)
        #expect(server.requests.count == 2)
    }

    @Test("A workflow that runs for 30 status requests gives pending")
    func pollLimit() async throws {
        let server = StubServer(status("Running"))
        let sleep = StubSleep(stopAt: .max)

        let result = try await wait(server, sleep: sleep)

        #expect(result == .pending)
        #expect(server.requests.count == 30)
    }

    @Test("The wait stops 60 seconds after its start, also when the requests are slow")
    func deadline() async throws {
        let server = StubServer(status("Running"))
        // Each read of the clock is 25 seconds after the one before it.
        let reads = Mutex(0)
        let now: @Sendable () -> Date = {
            let count = reads.withLock { value in
                value += 1
                return value
            }
            return Date(timeIntervalSince1970: TimeInterval(count * 25))
        }

        let result = try await wait(server, now: now)

        #expect(result == .pending)
        // The clock reads 25 at the start, then 50 and 75 before the third request.
        #expect(server.requests.count == 2)
    }

    @Test("A cancelled wait is a cancelled request, which shows no message")
    func cancelled() async throws {
        let server = StubServer(status("Running"))

        let error = await #expect(throws: RailwayError.self) {
            _ = try await wait(server, sleep: StubSleep(stopAt: 2))
        }
        guard case .cancelled? = error else {
            Issue.record("The error is \(String(describing: error)), not cancelled.")
            return
        }
        #expect(server.requests.count == 1)
    }
}
