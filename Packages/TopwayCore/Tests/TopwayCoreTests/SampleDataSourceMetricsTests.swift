import Foundation
import Testing

@testable import TopwayCore

struct SampleDataSourceMetricsTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    private func metrics(
        service: String = "storefront-web", window: MetricWindow = .hour
    ) async -> ServiceMetrics {
        await SampleDataSource(now: { [now] in now }).fetchMetrics(
            environmentId: "storefront-production", serviceId: service, window: window, token: "")
    }

    @Test("Each metric has one sample for each step of the time range, and the newest is now")
    func sampleTimes() async throws {
        let hour = await metrics()

        #expect(hour.series.map(\.kind) == MetricKind.allCases)
        for series in hour.series {
            #expect(series.samples.count == 120)
            #expect(series.samples.last?.date == now)
            #expect(series.samples.first?.date == now - 3_570)
            #expect(series.samples.allSatisfy { $0.value > 0 })
        }
        let day = await metrics(window: .day)
        #expect(day.series.first?.samples.count == 360)
    }

    @Test("The same service and time give the same samples")
    func deterministic() async {
        let first = await metrics()
        let second = await metrics()

        #expect(first == second)
    }

    @Test("Two services have different samples")
    func differentServices() async {
        let web = await metrics(service: "storefront-web")
        let api = await metrics(service: "storefront-api")

        #expect(web != api)
    }
}
