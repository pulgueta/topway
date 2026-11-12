import Foundation

/// The answer of the Railway `platformStatus` query.
struct PlatformStatus: Decodable, Sendable {
    let incident: PlatformIncident?

    /// The incident to show. `nil` when Railway reports no incident or a resolved incident.
    var openIncident: PlatformIncident? {
        incident.flatMap { $0.isOpen ? $0 : nil }
    }
}
