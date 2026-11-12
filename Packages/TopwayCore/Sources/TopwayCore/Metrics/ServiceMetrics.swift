/// The metrics of one service in one environment.
public struct ServiceMetrics: Hashable, Sendable {
    /// One series for each `MetricKind`, in the order of its cases.
    public let series: [MetricSeries]

    /// Railway gave no samples.
    public var isEmpty: Bool {
        series.allSatisfy(\.samples.isEmpty)
    }

    /// Railway can give more than one result for a measurement, for example one for each
    /// replica. Their values are added at each time, as the Sum view of Railway does.
    /// A measurement that is not a `MetricKind` is ignored.
    init(results: [MetricsResult]) {
        series = MetricKind.allCases.map { kind in
            var totals: [Int: Double] = [:]
            for result in results where result.measurement == kind.rawValue {
                for sample in result.values {
                    totals[sample.ts, default: 0] += sample.value
                }
            }
            return MetricSeries(
                kind: kind,
                samples: totals.sorted { $0.key < $1.key }.map {
                    MetricSample(ts: $0.key, value: $0.value)
                })
        }
    }
}
