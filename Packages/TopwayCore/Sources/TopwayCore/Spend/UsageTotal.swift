/// The use of one resource in a billing period, in the unit that Railway gives.
public struct UsageTotal: Identifiable, Hashable, Sendable {
    public let kind: UsageKind
    public let value: Double

    public init(kind: UsageKind, value: Double) {
        self.kind = kind
        self.value = value
    }

    public var id: UsageKind { kind }
}
