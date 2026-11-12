import Foundation
import Testing

@testable import TopwayCore

struct RailwayClientMetricsTests {
    @Test("The metrics request names the service, the environment and the time range")
    func request() async throws {
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"metrics":[
                      {"measurement":"CPU_USAGE","values":[{"ts":1794312000,"value":0.25}]}
                    ]}}
                    """))
        /// 2026-11-10T12:00:00Z.
        let now = Date(timeIntervalSince1970: 1_794_312_000)

        let metrics = try await RailwayClient(session: server.session, now: { now })
            .fetchMetrics(environmentId: "e1", serviceId: "s1", window: .sixHours, token: "secret")

        #expect(metrics.series.first?.latest == 0.25)
        let request = try #require(server.requests.first)
        #expect(request.authorization == "Bearer secret")
        #expect(
            request.variables == [
                "environmentId": "e1", "serviceId": "s1", "startDate": "2026-11-10T06:00:00Z",
            ])
        let query = try #require(request.query)
        #expect(query.contains("sampleRateSeconds: 60"))
        #expect(
            query.contains(
                "measurements: [CPU_USAGE, MEMORY_USAGE_GB, NETWORK_RX_GB, NETWORK_TX_GB]")
        )
    }
}
