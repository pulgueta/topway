/// What a custom domain waits for.
public enum DomainStatus: Sendable {
    /// One or more DNS records do not have the value that Railway needs.
    case needsRecords
    /// The DNS records are set, and Railway makes the certificate.
    case waitingForCertificate
    case ready

    public var title: String {
        switch self {
        case .needsRecords: "Set the DNS records"
        case .waitingForCertificate: "Railway makes the certificate"
        case .ready: "Ready"
        }
    }
}
