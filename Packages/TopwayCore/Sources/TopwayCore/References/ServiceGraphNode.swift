/// One end of a link between services.
public enum ServiceGraphNode: Hashable, Sendable {
    /// A service of the project, by ID.
    case service(id: String)
    /// The shared variables of the environment.
    case shared
    /// A name in a reference that no service of the project has.
    case missingService(name: String)
}
