/// What a custom domain waits for.
public enum DomainStatus: Sendable {
    /// One or more DNS records do not have the value that Railway needs.
    case needsRecords
    /// The DNS records are set, and Railway makes the certificate.
    case waitingForCertificate
    /// The DNS records are set, but Railway could not make the certificate.
    case certificateFailed
    case ready

    public var title: String {
        switch self {
        case .needsRecords: "Set the DNS records"
        case .waitingForCertificate: "Railway makes the certificate"
        case .certificateFailed: "Certificate failed"
        case .ready: "Ready"
        }
    }

    /// What the user can do, for a status that does not end by itself.
    public var advice: String? {
        switch self {
        case .certificateFailed:
            "Railway cannot make the certificate. Make sure that the DNS records are correct and that no CAA record of the domain blocks the certificate. Then delete the domain and add it again."
        case .needsRecords, .waitingForCertificate, .ready:
            nil
        }
    }
}
