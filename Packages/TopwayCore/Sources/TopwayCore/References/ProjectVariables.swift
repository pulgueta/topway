/// The unrendered variables of the services of a project in one environment, and the shared
/// variables of that environment. Topway uses the names to check references, and the values
/// to find the links between services.
public struct ProjectVariables: Hashable, Sendable {
    public let shared: [String: String]
    /// The variables of each service, by service ID.
    public let byService: [String: [String: String]]

    public init(shared: [String: String], byService: [String: [String: String]]) {
        self.shared = shared
        self.byService = byService
    }

    /// - Parameters:
    ///   - serviceId: The service that has the reference.
    ///   - services: The services of the project. The name of a reference is the name of
    ///     a service.
    public func status(of target: ReferenceTarget, from serviceId: String, services: [Service])
        -> ReferenceTargetStatus
    {
        let names: [String: String]
        switch target.namespace {
        case .sameService:
            names = byService[serviceId] ?? [:]
        case .shared:
            names = shared
        case .service(let name):
            // Railway matches the name of the service. The match is exact, as in the
            // examples of the Railway docs.
            guard let service = services.first(where: { $0.name == name }) else {
                return .missingService
            }
            names = byService[service.id] ?? [:]
        }

        if names[target.variableName] != nil {
            return .found
        }
        return target.variableName.hasPrefix("RAILWAY_") ? .setByRailway : .missingVariable
    }
}
