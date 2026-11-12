import Foundation
import Testing

@testable import TopwayCore

struct ServiceMetricsTests {
    private func decode(_ json: String) throws -> ServiceMetrics {
        let data = try JSONDecoder().decode(MetricsData.self, from: Data(json.utf8))
        return ServiceMetrics(results: data.metrics)
    }

    @Test("A Railway answer gives one series for each metric, in a fixed order")
    func decoding() throws {
        let metrics = try decode(
            """
            {"metrics":[
              {"measurement":"NETWORK_TX_GB","values":[{"ts":1794312000,"value":0.002}]},
              {"measurement":"MEMORY_USAGE_GB","values":[{"ts":1794312000,"value":0.5}]},
              {"measurement":"CPU_USAGE","values":[
                {"ts":1794312000,"value":0.25},{"ts":1794312030,"value":0.75}]},
              {"measurement":"NETWORK_RX_GB","values":[{"ts":1794312000,"value":0.001}]}
            ]}
            """)

        #expect(metrics.series.map(\.kind) == [.cpu, .memory, .networkIn, .networkOut])
        #expect(
            metrics.series.first?.samples == [
                MetricSample(ts: 1_794_312_000, value: 0.25),
                MetricSample(ts: 1_794_312_030, value: 0.75),
            ])
        #expect(
            metrics.series.first?.samples.first?.date
                == Date(timeIntervalSince1970: 1_794_312_000))
        #expect(!metrics.isEmpty)
    }

    @Test("A metric that Railway does not give has an empty series")
    func missingMeasurement() throws {
        let metrics = try decode(
            #"{"metrics":[{"measurement":"CPU_USAGE","values":[{"ts":10,"value":1}]}]}"#)

        #expect(metrics.series.count == 4)
        #expect(metrics.series.map(\.samples.count) == [1, 0, 0, 0])
        #expect(!metrics.isEmpty)
    }

    @Test("A measurement that Topway does not show is ignored")
    func unknownMeasurement() throws {
        let metrics = try decode(
            #"{"metrics":[{"measurement":"DISK_USAGE_GB","values":[{"ts":10,"value":1}]}]}"#)

        #expect(metrics.series.map(\.samples.count) == [0, 0, 0, 0])
        #expect(metrics.isEmpty)
    }

    @Test("No results give four empty series")
    func noResults() throws {
        let metrics = try decode(#"{"metrics":[]}"#)

        #expect(metrics.series.count == 4)
        #expect(metrics.isEmpty)
    }

    @Test("Two results of one measurement are added at each time, oldest first")
    func mergedResults() throws {
        let metrics = try decode(
            """
            {"metrics":[
              {"measurement":"MEMORY_USAGE_GB","values":[
                {"ts":60,"value":0.25},{"ts":30,"value":0.5}]},
              {"measurement":"MEMORY_USAGE_GB","values":[
                {"ts":30,"value":0.25},{"ts":90,"value":1}]}
            ]}
            """)

        #expect(
            metrics.series.first { $0.kind == .memory }?.samples == [
                MetricSample(ts: 30, value: 0.75),
                MetricSample(ts: 60, value: 0.25),
                MetricSample(ts: 90, value: 1),
            ])
    }

    @Test("A series gives its newest value and its highest value")
    func latestAndPeak() {
        let series = MetricSeries(
            kind: .cpu,
            samples: [
                MetricSample(ts: 10, value: 0.5),
                MetricSample(ts: 20, value: 2),
                MetricSample(ts: 30, value: 1),
            ])

        #expect(series.latest == 1)
        #expect(series.peak == 2)
    }

    @Test("An empty series has no newest value and no highest value")
    func emptySeries() {
        let series = MetricSeries(kind: .memory, samples: [])

        #expect(series.latest == nil)
        #expect(series.peak == nil)
    }
}
