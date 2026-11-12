/// Why a name for a new environment is not permitted.
public enum EnvironmentNameProblem: Sendable {
    case empty
    case duplicate

    /// The text that shows below the name field. An empty name shows no text, because the
    /// user did not type yet.
    public var message: String? {
        switch self {
        case .empty: nil
        case .duplicate: "This project has an environment with this name. Use a different name."
        }
    }
}
