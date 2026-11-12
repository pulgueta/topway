import Foundation
import Testing

@testable import TopwayCore

struct MetricWindowTests {
    /// 2026-11-10T12:00:00Z.
    private let now = Date(timeIntervalSince1970: 1_794_312_000)

    @Test("Each time range has a title")
    func titles() {
        #expect(
            MetricWindow.allCases.map(\.title) == ["Last hour", "Last 6 hours", "Last 24 hours"])
    }

    @Test(
        "A time range starts its length before now",
        arguments: [
            (MetricWindow.hour, 3_600.0), (.sixHours, 21_600.0), (.day, 86_400.0),
        ])
    func startDate(window: MetricWindow, length: TimeInterval) {
        #expect(window.startDate(now: now) == now - length)
    }

    @Test("A longer time range has more seconds between two samples")
    func sampleRates() {
        #expect(MetricWindow.allCases.map(\.sampleRateSeconds) == [30, 60, 240])
    }
}
