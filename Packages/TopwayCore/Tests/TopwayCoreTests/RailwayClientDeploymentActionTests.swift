import Foundation
import Testing

@testable import TopwayCore

struct RailwayClientDeploymentActionTests {
    @Test(
        "Each deployment action sends its mutation and gives the answer of Railway",
        arguments: ["deploymentRollback", "deploymentCancel", "deploymentRemove"], [true, false])
    func deploymentActions(field: String, answer: Bool) async throws {
        let server = StubServer(StubReply(body: #"{"data":{"\#(field)":\#(answer)}}"#))
        let client = RailwayClient(session: server.session)

        let result =
            switch field {
            case "deploymentRollback":
                try await client.rollbackDeployment(deploymentId: "d1", token: "secret")
            case "deploymentCancel":
                try await client.cancelDeployment(deploymentId: "d1", token: "secret")
            default:
                try await client.removeDeployment(deploymentId: "d1", token: "secret")
            }

        #expect(result == answer)
        let request = try #require(server.requests.first)
        #expect(request.variables == ["id": "d1"])
        #expect(try #require(request.query).contains("\(field)(id: $id)"))
    }

    @Test("The deployments request asks Railway if a rollback is possible")
    func deploymentsAskForRollback() async throws {
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"deployments":{"edges":[{"node":{"id":"d1","status":"REMOVED",
                      "staticUrl":null,"createdAt":"2026-11-10T10:00:00Z","canRollback":true}}]}}}
                    """))

        let deployments = try await RailwayClient(session: server.session).fetchDeployments(
            projectId: "p1", environmentId: "e1", serviceId: "s1", token: "secret")

        #expect(deployments.first?.availableActions == [.rollback])
        #expect(try #require(server.requests.first?.query).contains("canRollback"))
    }
}
