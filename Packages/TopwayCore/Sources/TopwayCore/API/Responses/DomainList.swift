/// The domains of a service in one environment, as Railway gives them.
struct DomainList: Decodable {
    let serviceDomains: [RailwayDomainNode]
    let customDomains: [CustomDomainNode]

    /// The Railway domains are first, because they need no action from the user.
    var domains: [Domain] {
        serviceDomains.map(\.model) + customDomains.map(\.model)
    }
}
