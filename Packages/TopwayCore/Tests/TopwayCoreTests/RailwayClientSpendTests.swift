import Foundation
import Testing

@testable import TopwayCore

struct RailwayClientSpendTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    private let customerReply = StubReply(
        body: """
            {"data":{"workspace":{"customer":{"currentUsage":12.34,
              "billingPeriod":{"start":"2026-11-01T00:00:00.000Z","end":"2026-12-01T00:00:00.000Z"},
              "usageLimit":{"softLimit":50,"hardLimit":null,"isOverLimit":false}}}}}
            """)

    @Test("Spend reads the cost first, then the usage from the period start to now")
    func requests() async throws {
        let server = StubServer(
            customerReply,
            StubReply(body: #"{"data":{"usage":[{"measurement":"CPU_USAGE","value":600}]}}"#))

        let spend = try await RailwayClient(session: server.session, now: { [now] in now })
            .fetchSpend(workspaceId: "w1", token: "secret")

        #expect(spend.cost == 12.34)
        #expect(spend.softLimit == 50)
        #expect(spend.usage.first == UsageTotal(kind: .cpu, value: 600))

        #expect(server.requests.count == 2)
        let first = try #require(server.requests.first)
        #expect(first.authorization == "Bearer secret")
        #expect(first.variables == ["workspaceId": "w1"])
        #expect(first.query?.contains("currentUsage") == true)
        let second = try #require(server.requests.last)
        #expect(second.authorization == "Bearer secret")
        #expect(
            second.variables == [
                "workspaceId": "w1", "startDate": "2026-11-01T00:00:00Z",
                "endDate": "2026-11-10T12:00:00Z",
            ])
        #expect(
            second.query?.contains(
                "measurements: [CPU_USAGE, MEMORY_USAGE_GB, NETWORK_TX_GB, DISK_USAGE_GB]") == true)
        // The cost that Railway gives includes deleted projects and services.
        #expect(second.query?.contains("includeDeleted: true") == true)
    }

    @Test("A Railway error for the usage is the error of the spend")
    func usageError() async throws {
        let server = StubServer(
            customerReply, StubReply(body: #"{"errors":[{"message":"Not Authorized"}]}"#))

        await #expect(throws: RailwayError.self) {
            try await RailwayClient(session: server.session, now: { [now] in now })
                .fetchSpend(workspaceId: "w1", token: "secret")
        }
        #expect(server.requests.count == 2)
    }
}
