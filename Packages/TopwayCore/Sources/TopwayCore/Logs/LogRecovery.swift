/// Decides what a log stream does after its socket fails.
///
/// Call `connected()` on each `connection_ack` and `payloadReceived()` on each `next` payload.
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

    private var isPassLive = false
    private var passHasPayload = false
    private var emptyLivePasses = 0

    mutating func connected() {
        isPassLive = true
    }

    mutating func payloadReceived() {
        passHasPayload = true
        emptyLivePasses = 0
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
        guard isPassLive else { return .poll }

        if !passHasPayload {
            emptyLivePasses += 1
        }
        guard emptyLivePasses < Self.emptyPassLimit else {
            // Bad data from the socket is not a network problem, so polling does not help.
            if case .networkError = error { return .poll }
            return .fail
        }
        return .reconnect(after: .seconds(2))
    }
}
