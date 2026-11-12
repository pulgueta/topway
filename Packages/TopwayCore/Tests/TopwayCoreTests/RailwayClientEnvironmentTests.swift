import Foundation
import Testing

@testable import TopwayCore

struct RailwayClientEnvironmentTests {
    @Test("Create environment gives the new ID, and sends no source when none is selected")
    func createWithNoSource() async throws {
        let server = StubServer(
            StubReply(body: #"{"data":{"environmentCreate":{"id":"e9","name":"preview"}}}"#))

        let id = try await RailwayClient(session: server.session).createEnvironment(
            projectId: "p1", name: "preview", sourceEnvironmentId: nil, token: "secret")

        #expect(id == "e9")
        let request = try #require(server.requests.first)
        #expect(request.variables == ["projectId": "p1", "name": "preview"])
        #expect(try #require(request.query).contains("environmentCreate"))
    }
}
