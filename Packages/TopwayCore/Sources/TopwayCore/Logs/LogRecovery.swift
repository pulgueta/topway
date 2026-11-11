/// What a log stream does after its socket fails.
enum LogRecovery: Equatable {
    /// The socket was live and dropped. Connect again.
    case reconnect
    /// The socket did not connect. Poll the matching query.
    case poll
    /// Railway answered with an error. Polling gets the same answer, so stop.
    case fail

    init(after error: RailwayError, wasLive: Bool) {
        switch error {
        case .networkError, .decodingError, .unknown:
            self = wasLive ? .reconnect : .poll
        case .invalidURL, .graphQLError, .unauthorized, .rateLimited, .httpStatus, .cancelled:
            self = .fail
        }
    }
}
