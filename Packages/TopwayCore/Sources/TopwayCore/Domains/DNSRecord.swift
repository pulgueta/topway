/// A DNS record that the user must set at the DNS provider of a custom domain.
public struct DNSRecord: Identifiable, Hashable, Sendable {
    /// The record type, for example `CNAME` or `TXT`.
    public let type: String
    /// The host of the record in its zone. `@` is the zone itself.
    public let name: String
    /// The value that the record must have.
    public let value: String
    /// Railway sees the value in the DNS.
    public let isSet: Bool

    /// Two records can have the same type and name, for example two A records, so the
    /// value is part of the id.
    public var id: String { "\(type) \(name) \(value)" }

    public init(type: String, name: String, value: String, isSet: Bool) {
        self.type = type
        self.name = name
        self.value = value
        self.isSet = isSet
    }
}
