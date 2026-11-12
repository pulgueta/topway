import Foundation

/// The sample metrics. They come only from the service, the environment and the date,
/// so the same inputs give the same chart.
extension SampleDataSource {
    /// The middle value of each metric: vCPU for CPU, GB for the others.
    private static let metricLevels: [(kind: MetricKind, level: Double)] = [
        (.cpu, 0.4), (.memory, 0.6), (.networkIn, 0.004), (.networkOut, 0.01),
    ]

    /// Each metric is a wave around its level. The newest sample is at `now`.
    static func sampleMetrics(
        environmentId: String, serviceId: String, window: MetricWindow, now: Date
    ) -> ServiceMetrics {
        // The sum of the bytes gives each service its own level and its own wave.
        let seed = "\(environmentId)/\(serviceId)".utf8.reduce(0) { $0 + Int($1) }
        let count = window.seconds / window.sampleRateSeconds
        let end = Int(now.timeIntervalSince1970)

        return ServiceMetrics(
            results: metricLevels.enumerated().map { offset, metric in
                let level = metric.level * (0.5 + Double(seed % 7) / 4)
                let phase = Double(seed % 13 + offset * 3)
                return MetricsResult(
                    measurement: metric.kind.rawValue,
                    values: (0..<count).map { index in
                        let wave = sin(Double(index) / 9 + phase) * 0.35
                        return MetricSample(
                            ts: end - (count - 1 - index) * window.sampleRateSeconds,
                            value: level * (1 + wave))
                    })
            })
    }
}
