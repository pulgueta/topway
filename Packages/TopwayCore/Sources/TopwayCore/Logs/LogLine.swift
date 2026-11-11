/// One line of a build log or a deploy log.
public struct LogLine: Decodable, Hashable, Sendable {
    /// The time in RFC 3339 format, with nanoseconds.
    public let timestamp: String
    public let message: String
    /// The severity that Railway gives, for example `info` or `err`.
    let severity: String?

    public init(timestamp: String, message: String, severity: String?) {
        self.timestamp = timestamp
        self.message = message
        self.severity = severity
    }

    public var level: LogLevel {
        switch severity?.lowercased() {
        case "warn", "warning": .warning
        case "err", "error", "fatal", "critical", "panic": .error
        default: .info
        }
    }
}
