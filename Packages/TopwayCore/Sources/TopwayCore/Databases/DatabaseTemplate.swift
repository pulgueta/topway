/// A database that Railway deploys from a template. The raw value is the template code
/// on Railway, as the Railway CLI uses it.
public enum DatabaseTemplate: String, CaseIterable, Identifiable, Sendable {
    case postgres
    case mysql
    case redis
    case mongo

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .postgres: "PostgreSQL"
        case .mysql: "MySQL"
        case .redis: "Redis"
        case .mongo: "MongoDB"
        }
    }
}
