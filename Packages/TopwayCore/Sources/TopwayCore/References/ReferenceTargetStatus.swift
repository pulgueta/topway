/// Whether the variable of a reference exists.
public enum ReferenceTargetStatus: Hashable, Sendable {
    case found
    /// The project has no service with the name of the reference.
    case missingService
    /// The service or the shared variables have no variable with this name.
    case missingVariable
    /// A `RAILWAY_` variable, such as `RAILWAY_PUBLIC_DOMAIN`. Railway sets it, and the list
    /// of Railway does not always have it, so Topway cannot check it.
    case setByRailway
    /// The variables of the other services did not load.
    case notChecked

    /// The text that the row shows next to the target.
    public var label: String {
        switch self {
        case .found: "Found"
        case .missingService: "Service not found"
        case .missingVariable: "Variable not found"
        case .setByRailway: "Set by Railway"
        case .notChecked: "Not checked"
        }
    }
}
