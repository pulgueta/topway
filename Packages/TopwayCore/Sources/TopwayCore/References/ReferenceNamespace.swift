/// The part of a Railway reference before the dot: the place that has the variable.
public enum ReferenceNamespace: Hashable, Sendable {
    /// `${{VAR}}`: a variable of the same service.
    case sameService
    /// `${{shared.VAR}}`: a shared variable of the environment.
    case shared
    /// `${{api.VAR}}`: a variable of the service with this name.
    case service(String)
}
