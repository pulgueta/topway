/// The links between the services of a project in one environment. A reference to a
/// variable of a different service, or to a shared variable, gives a link. A reference to
/// the same service gives no link. Two services can link to each other.
public struct ServiceGraph: Hashable, Sendable {
    /// The services of the environment, in the order of the project.
    public let services: [Service]
    /// One edge for each pair of ends, in the order of the services, then of the variable
    /// names. The shared variables come last.
    public let edges: [ServiceGraphEdge]

    public init(services: [Service], variables: ProjectVariables) {
        self.services = services
        let idsByName = Dictionary(
            services.map { ($0.name, $0.id) }, uniquingKeysWith: { first, _ in first })

        var pairs: [(from: ServiceGraphNode, to: ServiceGraphNode)] = []
        var names: [ServiceGraphNode: [ServiceGraphNode: Set<String>]] = [:]
        func addLinks(from source: ServiceGraphNode, values: [String: String]) {
            for (name, value) in values.sorted(by: { $0.key < $1.key }) {
                for reference in VariableReference.all(in: value) {
                    let target: ServiceGraphNode
                    switch reference.target.namespace {
                    case .sameService:
                        continue
                    case .shared:
                        target = .shared
                    case .service(let serviceName):
                        target =
                            idsByName[serviceName].map { .service(id: $0) }
                            ?? .missingService(name: serviceName)
                    }
                    // A service that names itself has no link to a different node.
                    guard target != source else { continue }
                    if names[source]?[target] == nil {
                        pairs.append((source, target))
                    }
                    names[source, default: [:]][target, default: []].insert(name)
                }
            }
        }

        for service in services {
            addLinks(from: .service(id: service.id), values: variables.byService[service.id] ?? [:])
        }
        addLinks(from: .shared, values: variables.shared)
        edges = pairs.map {
            ServiceGraphEdge(
                from: $0.from, to: $0.to, variableNames: (names[$0.from]?[$0.to] ?? []).sorted())
        }
    }

    /// The services, then the shared variables when a link uses them.
    public var nodes: [ServiceGraphNode] {
        let usesShared = edges.contains { $0.from == .shared || $0.to == .shared }
        return services.map { .service(id: $0.id) } + (usesShared ? [.shared] : [])
    }

    /// The links that start at a node.
    public func uses(_ node: ServiceGraphNode) -> [ServiceGraphEdge] {
        edges.filter { $0.from == node }
    }

    /// The links that end at a node.
    public func usedBy(_ node: ServiceGraphNode) -> [ServiceGraphEdge] {
        edges.filter { $0.to == node }
    }

    /// The text of a node: the service name, "Shared variables", or the missing name.
    public func name(of node: ServiceGraphNode) -> String {
        switch node {
        case .service(let id): services.first { $0.id == id }?.name ?? id
        case .shared: "Shared variables"
        case .missingService(let name): name
        }
    }

    /// The link as one sentence, for VoiceOver. It has names only, never a value.
    public func sentence(for edge: ServiceGraphEdge) -> String {
        let subject =
            edge.from == .shared ? "The shared variables use" : "\(name(of: edge.from)) uses"
        let object = edge.to == .shared ? "the shared variables" : name(of: edge.to)
        let sentence =
            "\(subject) \(object) in \(edge.variableNames.joined(separator: ", "))."
        if case .missingService = edge.to {
            return sentence + " The project has no service with this name."
        }
        return sentence
    }
}
