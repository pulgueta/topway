import TopwayCore

/// The state of the log stream that the logs screen shows.
enum LogStreamState {
    case connecting
    case connection(LogConnection)
    /// The stream finished with no error.
    case ended
    /// An error stopped the stream. `ErrorBanner` or `ErrorStateView` shows it.
    case stopped
}
