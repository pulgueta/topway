import Foundation
import Testing

@testable import TopwayCore

struct RailwayClientPlatformStatusTests {
    @Test("The platform status request has no token and no variables")
    func request() async throws {
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"platformStatus":{"incident":{"id":"97GIDVEY",
                      "message":"GitHub Outage Affecting Builds","status":"MONITORING",
                      "url":"https://status.railway.com"}}}}
                    """))

        let incident = try await RailwayClient(session: server.session).fetchOpenIncident()

        #expect(incident?.message == "GitHub Outage Affecting Builds")
        let request = try #require(server.requests.first)
        #expect(request.url?.absoluteString == "https://backboard.railway.com/graphql/v2")
        #expect(request.authorization == nil)
        #expect(request.variables == [:])
        #expect(request.query?.contains("platformStatus") == true)
    }

    @Test("No incident from Railway gives no incident")
    func noIncident() async throws {
        let server = StubServer(StubReply(body: #"{"data":{"platformStatus":{"incident":null}}}"#))

        #expect(try await RailwayClient(session: server.session).fetchOpenIncident() == nil)
    }
}
