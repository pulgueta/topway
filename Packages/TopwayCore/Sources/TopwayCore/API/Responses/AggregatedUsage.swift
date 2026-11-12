/// The total of one measurement. `measurement` is a Railway `MetricMeasurement`.
struct AggregatedUsage: Decodable, Sendable {
    let measurement: String
    let value: Double
}
