/// Decides what a log stream does after its socket fails.
///
/// Call `connected()` on each `connection_ack`, `payloadReceived()` on each `next` payload,
/// and `retryingFromPolling()` before a socket try from polling.
struct LogRecovery {
    enum Step: Equatable {
        /// Connect the socket again after the delay.
        case reconnect(after: Duration)
        /// Poll the matching query.
        case poll
        /// Stop the stream with the error.
        case fail
    }

    /// A socket can connect and then fail before it gives a payload, each time. After this
    /// number of such passes in a row, the stream stops connecting again.
    static let emptyPassLimit = 3
    /// After a live socket drops, the reconnects that do not connect, in a row, before
    /// the stream polls. With the backoff, this is about 60 seconds of reconnects.
    static let failedReconnectLimit = 5
    /// The longest wait before a reconnect.
    static let maximumDelay = Duration.seconds(30)

    /// The socket connected one or more times in this stream.
    private var hasBeenLive = false
    private var isPassLive = false
    private var passHasPayload = false
    private var isRetryFromPolling = false
    private var emptyLivePasses = 0
    private var failedReconnects = 0
    /// The reconnects since the last payload. It sets the delay: 2, 4, 8, 16, then 30 seconds.
    private var reconnects = 0

    mutating func connected() {
        hasBeenLive = true
        isPassLive = true
        isRetryFromPolling = false
        failedReconnects = 0
    }

    mutating func retryingFromPolling() {
        isRetryFromPolling = true
    }

    mutating func payloadReceived() {
        passHasPayload = true
        emptyLivePasses = 0
        reconnects = 0
    }

    mutating func step(after error: RailwayError) -> Step {
        defer {
            isPassLive = false
            passHasPayload = false
        }
        let isSocketFailure: Bool =
            switch error {
            case .networkError, .decodingError, .unknown: true
            // Railway answered. Polling gets the same answer.
            case .invalidURL, .graphQLError, .unauthorized, .rateLimited, .httpStatus, .cancelled:
                false
            }
        guard isSocketFailure else { return .fail }

        if isPassLive {
            if !passHasPayload {
                emptyLivePasses += 1
            }
            guard emptyLivePasses < Self.emptyPassLimit else {
                // Bad data from the socket is not a network problem, so polling does not help.
                if case .networkError = error { return .poll }
                return .fail
            }
        } else if isRetryFromPolling || !hasBeenLive {
            // The socket did not connect. Polling tries it again later.
            return .poll
        } else {
            // A reconnect after a live drop did not connect.
            failedReconnects += 1
            guard failedReconnects < Self.failedReconnectLimit else { return .poll }
        }

        let delay = min(.seconds(2 << min(reconnects, 4)), Self.maximumDelay)
        reconnects += 1
        return .reconnect(after: delay)
    }
}
