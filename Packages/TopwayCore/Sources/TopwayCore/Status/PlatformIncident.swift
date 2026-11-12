import Foundation

/// An incident that Railway reports, from the `platformStatus` query.
public struct PlatformIncident: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    /// The title of the incident, for example "Builds are slow".
    public let message: String
    /// A Railway `IncidentStatus`: INVESTIGATING, IDENTIFIED, MONITORING or RESOLVED.
    let status: String
    let url: String

    public init(id: String, message: String, status: String, url: String) {
        self.id = id
        self.message = message
        self.status = status
        self.url = url
    }

    /// The Railway status page. The banner opens it when the incident has no safe link.
    public static let statusPage = URL(string: "https://status.railway.com")!

    /// Railway works on the incident. A resolved incident is not open.
    public var isOpen: Bool {
        status.uppercased() != "RESOLVED"
    }

    /// The status in words, for example "Investigating".
    public var statusDisplay: String {
        status.replacing("_", with: " ").capitalized
    }

    /// The page of the incident. Only an HTTPS page on railway.com is safe to open.
    /// Other values give the Railway status page.
    public var link: URL {
        guard let link = URL(string: url), link.scheme == "https", let host = link.host(),
            host == "railway.com" || host.hasSuffix(".railway.com")
        else { return Self.statusPage }
        return link
    }
}
