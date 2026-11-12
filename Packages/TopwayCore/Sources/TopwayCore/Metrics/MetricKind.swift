import Foundation

/// The service metrics that Topway shows. The raw value is the Railway `MetricMeasurement`.
public enum MetricKind: String, CaseIterable, Identifiable, Sendable {
    case cpu = "CPU_USAGE"
    case memory = "MEMORY_USAGE_GB"
    case networkIn = "NETWORK_RX_GB"
    case networkOut = "NETWORK_TX_GB"

    public var id: Self { self }

    public var title: String {
        switch self {
        case .cpu: "CPU"
        case .memory: "Memory"
        case .networkIn: "Network in"
        case .networkOut: "Network out"
        }
    }

    /// The text of a value, with its unit. Railway gives CPU in vCPU and sizes in GB.
    public func formatted(_ value: Double) -> String {
        switch self {
        case .cpu: Self.cpuText(value)
        case .memory, .networkIn, .networkOut: Self.sizeText(gigabytes: value)
        }
    }

    private static func cpuText(_ value: Double) -> String {
        switch value {
        case 0: "0 vCPU"
        case ..<0.01: "< 0.01 vCPU"
        case ..<1: String(format: "%.2f vCPU", value)
        default: String(format: "%.1f vCPU", value)
        }
    }

    /// Shows MB below 1 GB, so a small value does not show as "0.00 GB". A value that is not
    /// zero and is below 0.1 MB shows as "< 0.1 MB", so it does not show as "0.0 MB".
    private static func sizeText(gigabytes: Double) -> String {
        let megabytes = gigabytes * 1_024
        switch gigabytes {
        case 0: return "0 MB"
        case _ where megabytes < 0.1: return "< 0.1 MB"
        case ..<1: return String(format: megabytes < 10 ? "%.1f MB" : "%.0f MB", megabytes)
        case ..<10: return String(format: "%.2f GB", gigabytes)
        default: return String(format: "%.1f GB", gigabytes)
        }
    }
}
