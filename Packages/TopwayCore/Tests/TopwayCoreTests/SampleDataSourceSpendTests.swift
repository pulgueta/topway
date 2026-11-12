import Foundation
import Testing

@testable import TopwayCore

struct SampleDataSourceSpendTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    @Test("The sample spend has a cost, limits, usage, and a billing period around now")
    func spend() async {
        let spend = await SampleDataSource(now: { [now] in now })
            .fetchSpend(workspaceId: "", token: "")

        #expect(spend.cost == 23.47)
        #expect(spend.periodStart == now - 12 * 86_400)
        #expect(spend.daysLeft(now: now) == 18)
        #expect(spend.softLimit == 50)
        #expect(spend.hardLimit == 100)
        #expect(!spend.isOverLimit)
        #expect(spend.usage.map(\.kind) == UsageKind.allCases)
        #expect(spend.usage.allSatisfy { $0.value > 0 })
    }
}
