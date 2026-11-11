/// The two logs of a deployment.
public enum LogKind: Sendable, CaseIterable {
    case build
    case deploy

    /// The Railway query and subscription field.
    var fieldName: String {
        switch self {
        case .build: "buildLogs"
        case .deploy: "deploymentLogs"
        }
    }
}
