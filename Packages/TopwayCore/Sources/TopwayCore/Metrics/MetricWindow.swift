import Foundation

/// The time range of the metrics.
public enum MetricWindow: String, CaseIterable, Identifiable, Sendable {
    case hour
    case sixHours
    case day

    public var id: Self { self }

    public var title: String {
        switch self {
        case .hour: "Last hour"
        case .sixHours: "Last 6 hours"
        case .day: "Last 24 hours"
        }
    }

    var seconds: Int {
        switch self {
        case .hour: 3_600
        case .sixHours: 21_600
        case .day: 86_400
        }
    }

    /// The seconds between two samples. The Railway CLI uses the same values for these
    /// time ranges, so a chart has 120 to 360 samples.
    var sampleRateSeconds: Int {
        switch self {
        case .hour: 30
        case .sixHours: 60
        case .day: 240
        }
    }

    /// The date of the oldest sample to read.
    func startDate(now: Date) -> Date {
        now - TimeInterval(seconds)
    }
}
