/// How a log stream gets its lines.
public enum LogConnection: Sendable {
    /// The WebSocket subscription is open.
    case live
    /// The socket dropped, and the stream connects again.
    case reconnecting
    /// The socket is not available, so the stream reads the logs at a fixed interval.
    case polling
}
