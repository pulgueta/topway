/// A domain that Railway made. Railway names it a service domain.
struct RailwayDomainNode: Decodable {
    let id: String
    let domain: String

    var model: Domain {
        Domain(id: id, name: domain, kind: .railway)
    }
}
