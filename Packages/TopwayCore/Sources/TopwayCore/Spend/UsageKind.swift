import Foundation

/// The resources that Railway bills by use. The raw value is the Railway `MetricMeasurement`.
public enum UsageKind: String, CaseIterable, Identifiable, Sendable {
    case cpu = "CPU_USAGE"
    case memory = "MEMORY_USAGE_GB"
    case egress = "NETWORK_TX_GB"
    case volume = "DISK_USAGE_GB"

    public var id: Self { self }

    public var title: String {
        switch self {
        case .cpu: "CPU"
        case .memory: "Memory"
        case .egress: "Network egress"
        case .volume: "Volumes"
        }
    }

    /// The text of a usage total, with its unit. Railway gives vCPU-minutes for CPU,
    /// GB-minutes for memory and volumes, and GB for the network. The Railway CLI
    /// (`src/commands/usage.rs`) reads the same values with prices for each minute.
    /// Topway shows hours, because the numbers are shorter.
    public func formatted(_ value: Double) -> String {
        switch self {
        case .cpu: String(format: "%.1f vCPU-hours", value / 60)
        case .memory, .volume: String(format: "%.1f GB-hours", value / 60)
        case .egress: String(format: "%.2f GB", value)
        }
    }
}
