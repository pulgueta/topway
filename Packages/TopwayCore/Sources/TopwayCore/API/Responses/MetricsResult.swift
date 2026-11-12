/// The samples of one measurement. `measurement` is a Railway `MetricMeasurement`.
struct MetricsResult: Decodable, Sendable {
    let measurement: String
    let values: [MetricSample]
}
