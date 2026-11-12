import Foundation

/// Why Topway cannot deploy a template.
public enum TemplateConfigProblem: LocalizedError, Equatable {
    /// Railway gave no configuration for the template.
    case noConfiguration
    /// The template needs a value that only the user can give.
    case missingVariable(String)

    public var errorDescription: String? {
        switch self {
        case .noConfiguration:
            "Railway gave no configuration for this database. Try again later."
        case .missingVariable(let name):
            "Topway cannot add this database, because its template needs a value for \(name). Add it on Railway."
        }
    }
}
