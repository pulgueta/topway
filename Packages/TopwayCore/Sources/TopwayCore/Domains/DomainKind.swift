public enum DomainKind: Sendable {
    /// A domain that Railway makes, for example `web-production.up.railway.app`.
    case railway
    /// A domain of the user. The user sets its DNS records.
    case custom

    public var title: String {
        switch self {
        case .railway: "Railway domain"
        case .custom: "Custom domain"
        }
    }
}
