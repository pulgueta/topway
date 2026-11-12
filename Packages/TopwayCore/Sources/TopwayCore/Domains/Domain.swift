/// A domain of a service in one environment.
public struct Domain: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: DomainKind
    /// The DNS records of a custom domain. A Railway domain has none.
    public let records: [DNSRecord]
    /// Railway has a valid certificate for the custom domain.
    let hasCertificate: Bool

    public init(
        id: String, name: String, kind: DomainKind, records: [DNSRecord] = [],
        hasCertificate: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.records = records
        self.hasCertificate = hasCertificate
    }

    /// `nil` for a Railway domain, which needs no DNS records from the user.
    public var status: DomainStatus? {
        guard kind == .custom else { return nil }
        if records.contains(where: { !$0.isSet }) { return .needsRecords }
        return hasCertificate ? .ready : .waitingForCertificate
    }
}
