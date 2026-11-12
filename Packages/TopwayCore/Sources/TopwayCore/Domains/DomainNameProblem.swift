/// Why a name for a custom domain is not permitted.
public enum DomainNameProblem: Sendable {
    case empty
    case invalid
    case railwayDomain
    case duplicate

    /// The text that shows below the field. An empty name shows no text, because the user
    /// did not type yet.
    public var message: String? {
        switch self {
        case .empty: nil
        case .invalid: "Enter a domain name, for example app.example.com."
        case .railwayDomain: "Railway makes this domain. Select Add Railway domain."
        case .duplicate: "This service has this domain."
        }
    }
}
