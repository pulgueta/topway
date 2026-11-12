/// A setting of a service in one environment that Topway can change. The raw value is the
/// field name of `ServiceInstanceUpdateInput` on Railway.
public enum ServiceSetting: String, CaseIterable, Sendable {
    case buildCommand
    case startCommand
    case rootDirectory
    case healthcheckPath

    public var title: String {
        switch self {
        case .buildCommand: "Build command"
        case .startCommand: "Start command"
        case .rootDirectory: "Root directory"
        case .healthcheckPath: "Healthcheck path"
        }
    }

    /// An example value, for the empty field.
    public var example: String {
        switch self {
        case .buildCommand: "npm run build"
        case .startCommand: "npm run start"
        case .rootDirectory: "/apps/web"
        case .healthcheckPath: "/health"
        }
    }
}
