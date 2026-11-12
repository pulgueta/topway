/// The samples of one metric, oldest first.
public struct MetricSeries: Identifiable, Hashable, Sendable {
    public let kind: MetricKind
    public let samples: [MetricSample]

    public init(kind: MetricKind, samples: [MetricSample]) {
        self.kind = kind
        self.samples = samples
    }

    public var id: MetricKind { kind }

    /// The newest value. `nil` when Railway gave no samples.
    public var latest: Double? {
        samples.last?.value
    }

    /// The highest value. `nil` when Railway gave no samples.
    public var peak: Double? {
        samples.map(\.value).max()
    }
}
