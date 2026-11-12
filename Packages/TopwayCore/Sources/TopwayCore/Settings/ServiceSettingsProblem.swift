/// Why Topway cannot save the settings of a service.
public enum ServiceSettingsProblem: Sendable {
    case emptyName
    case healthcheckPath

    public var message: String {
        switch self {
        case .emptyName: "Enter a name for the service."
        case .healthcheckPath: "The healthcheck path must start with a slash (/)."
        }
    }
}
