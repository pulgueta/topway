import Foundation
import Testing

@testable import TopwayCore

struct SpendTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    private func spend(
        limit: String = #"{"softLimit":75,"hardLimit":125,"isOverLimit":false}"#,
        usage: String = "[]"
    ) throws -> Spend {
        let customer = try JSONDecoder().decode(
            Customer.self,
            from: Data(
                """
                {"currentUsage":50.5,
                 "billingPeriod":{"start":"2026-11-01T00:00:00.000Z","end":"2026-12-01T00:00:00Z"},
                 "usageLimit":\(limit)}
                """.utf8))
        let totals = try JSONDecoder().decode([AggregatedUsage].self, from: Data(usage.utf8))
        return Spend(customer: customer, usage: totals)
    }

    @Test("A Railway answer gives the cost, the billing period and the limits")
    func decoding() throws {
        let spend = try spend()

        #expect(spend.cost == 50.5)
        #expect(spend.periodStart == Date(timeIntervalSince1970: 1_793_491_200))
        #expect(spend.periodEnd == Date(timeIntervalSince1970: 1_796_083_200))
        #expect(spend.softLimit == 75)
        #expect(spend.hardLimit == 125)
        #expect(!spend.isOverLimit)
    }

    @Test("With no usage limit from Railway, no limit is set")
    func noLimit() throws {
        let spend = try spend(limit: "null")

        #expect(spend.softLimit == nil)
        #expect(spend.hardLimit == nil)
        #expect(!spend.isOverLimit)
        #expect(spend.limitUse == nil)
    }

    @Test("A soft limit of 0 is not set, and the hard limit can be missing")
    func softLimitOnly() throws {
        let unset = try spend(limit: #"{"softLimit":0,"hardLimit":null,"isOverLimit":false}"#)
        #expect(unset.softLimit == nil)
        #expect(unset.limitUse == nil)

        let soft = try spend(limit: #"{"softLimit":101,"hardLimit":null,"isOverLimit":true}"#)
        #expect(soft.softLimit == 101)
        #expect(soft.hardLimit == nil)
        #expect(soft.isOverLimit)
        #expect(soft.limitUse == 0.5)
    }

    @Test("The limit use is the cost as a part of the hard limit")
    func limitUse() throws {
        let spend = try spend(limit: #"{"softLimit":75,"hardLimit":202,"isOverLimit":false}"#)

        #expect(spend.limitUse == 0.25)
    }

    @Test("A date that is not ISO 8601 is a decoding error")
    func badDate() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                BillingPeriod.self, from: Data(#"{"start":"today","end":"2026-12-01"}"#.utf8))
        }
    }

    @Test("Usage has one total for each resource, and adds the values of one measurement")
    func usageTotals() throws {
        let spend = try spend(
            usage: """
                [{"measurement":"NETWORK_TX_GB","value":1.5},
                 {"measurement":"CPU_USAGE","value":100},
                 {"measurement":"CPU_USAGE","value":20},
                 {"measurement":"BACKUP_USAGE_GB","value":9}]
                """)

        #expect(
            spend.usage == [
                UsageTotal(kind: .cpu, value: 120), UsageTotal(kind: .memory, value: 0),
                UsageTotal(kind: .egress, value: 1.5), UsageTotal(kind: .volume, value: 0),
            ])
    }

    @Test(
        "A part of a day counts as one day left, and no days are left after the end",
        arguments: [
            // 2026-11-10T12:00:00Z, 2026-11-30T00:00:00Z, 2026-11-30T23:59:00Z, the end, later.
            (1_794_312_000.0, 21), (1_795_996_800.0, 1), (1_796_083_140.0, 1),
            (1_796_083_200.0, 0), (1_796_100_000.0, 0),
        ])
    func daysLeft(time: TimeInterval, days: Int) throws {
        #expect(try spend().daysLeft(now: Date(timeIntervalSince1970: time)) == days)
    }

    @Test(
        "An amount shows in US dollars with two decimals",
        arguments: [(0, "$0.00"), (50.5, "$50.50"), (1_234.5, "$1,234.50")])
    func dollars(amount: Double, text: String) throws {
        #expect(Spend.dollars(amount) == text)
    }

    @Test("A Not Authorized answer is about billing access, not about a rejected token")
    func unauthorizedMessage() {
        #expect(
            Spend.failureMessage(for: .unauthorized)
                == "Your Railway account cannot read the billing of this workspace. Railway shows the billing only to workspace admins."
        )
    }

    @Test("Other errors keep their message, and a cancelled load has no message")
    func otherMessages() {
        #expect(
            Spend.failureMessage(for: .graphQLError("Workspace not found"))
                == "Railway sent an error: Workspace not found")
        #expect(Spend.failureMessage(for: .unknown) == "An error occurred. Try again.")
        #expect(Spend.failureMessage(for: .cancelled) == nil)
    }

    @Test("The cost text is the cost in US dollars")
    func formattedCost() throws {
        #expect(try spend().formattedCost == "$50.50")
    }
}
