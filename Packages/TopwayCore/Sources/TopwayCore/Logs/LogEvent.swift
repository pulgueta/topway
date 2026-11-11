/// An event of a log stream.
public enum LogEvent: Equatable, Sendable {
    /// New lines, oldest first. A stream gives each line one time only.
    case lines([LogLine])
    case connection(LogConnection)
}
