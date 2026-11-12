import Foundation

/// One sample of a metric, as Railway gives it.
public struct MetricSample: Decodable, Hashable, Sendable {
    /// Seconds since 1970.
    let ts: Int
    public let value: Double

    public init(ts: Int, value: Double) {
        self.ts = ts
        self.value = value
    }

    public var date: Date {
        Date(timeIntervalSince1970: TimeInterval(ts))
    }
}
