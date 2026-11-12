import Foundation
import Testing

@testable import TopwayCore

struct RailwayClientServiceSettingsTests {
    @Test("The settings request names the service and the environment")
    func fetch() async throws {
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"serviceInstance":{"serviceName":"web","source":null,
                      "buildCommand":"make","startCommand":null,"rootDirectory":null,
                      "healthcheckPath":null}}}
                    """))

        let settings = try await RailwayClient(session: server.session).fetchServiceSettings(
            environmentId: "e1", serviceId: "s1", token: "secret")

        #expect(settings == ServiceSettings(name: "web", values: [.buildCommand: "make"]))
        let request = try #require(server.requests.first)
        #expect(request.variables == ["environmentId": "e1", "serviceId": "s1"])
        let query = try #require(request.query)
        for field in ["serviceName", "buildCommand", "startCommand", "rootDirectory"] {
            #expect(query.contains(field))
        }
    }

    @Test("A save sends the name, then only the changed settings, and null removes a setting")
    func update() async throws {
        let server = StubServer(
            StubReply(body: #"{"data":{"serviceUpdate":{"id":"s1"}}}"#),
            StubReply(body: #"{"data":{"serviceInstanceUpdate":true}}"#))
        let changes = ServiceSettingsChanges(
            name: "storefront", instance: [.startCommand: "npm start", .healthcheckPath: ""])

        let didSave = try await RailwayClient(session: server.session).updateServiceSettings(
            changes, environmentId: "e1", serviceId: "s1", token: "secret")

        #expect(didSave)
        let requests = server.requests
        try #require(requests.count == 2)
        #expect(requests[0].variables == ["id": "s1", "name": "storefront"])
        #expect(try #require(requests[0].query).contains("serviceUpdate"))
        #expect(
            requests[1].variablesJSON
                == #"{"environmentId":"e1","input":{"healthcheckPath":null,"startCommand":"npm start"},"serviceId":"s1"}"#
        )
        #expect(try #require(requests[1].query).contains("serviceInstanceUpdate"))
    }

    @Test("A save with no new name sends one request and gives the answer of Railway")
    func updateInstanceOnly() async throws {
        let server = StubServer(StubReply(body: #"{"data":{"serviceInstanceUpdate":false}}"#))

        let didSave = try await RailwayClient(session: server.session).updateServiceSettings(
            ServiceSettingsChanges(instance: [.buildCommand: "make"]), environmentId: "e1",
            serviceId: "s1", token: "secret")

        #expect(!didSave)
        #expect(server.requests.count == 1)
    }

    @Test(
        "A setting reaches the request JSON unchanged, and only through variables",
        arguments: [#"sh -c "echo \"hi\"""#, "line one\nline two", "${{ shared.CMD }}"])
    func inputTravelsThroughVariables(input: String) async throws {
        let server = StubServer(StubReply(body: #"{"data":{"serviceInstanceUpdate":true}}"#))

        _ = try await RailwayClient(session: server.session).updateServiceSettings(
            ServiceSettingsChanges(instance: [.startCommand: input]), environmentId: "e1",
            serviceId: "s1", token: "secret")

        let request = try #require(server.requests.first)
        let expected = try JSONSerialization.data(
            withJSONObject: [
                "environmentId": "e1", "serviceId": "s1", "input": ["startCommand": input],
            ], options: [.sortedKeys, .withoutEscapingSlashes])
        #expect(request.variablesJSON == String(decoding: expected, as: UTF8.self))
        let query = try #require(request.query)
        #expect(!query.contains(input))
        #expect(!query.contains("\""))
    }
}
