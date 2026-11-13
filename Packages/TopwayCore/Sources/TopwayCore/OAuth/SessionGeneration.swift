/// Marks the sign-in that was current when a request started. A request that ends in a later
/// generation must not change the screen or the saved state: the user signed out, started
/// another sign-in or selected sample data while it waited.
public struct SessionGeneration: Sendable, Equatable {
    public enum Event: Sendable {
        case signInStarted
        case signedOut
        case sampleModeStarted
        /// A refresh keeps the same sign-in, so requests that wait for it stay current.
        case tokensRefreshed
    }

    private var value = 0

    public init() {}

    public mutating func record(_ event: Event) {
        switch event {
        case .signInStarted, .signedOut, .sampleModeStarted:
            value += 1
        case .tokensRefreshed:
            break
        }
    }

    /// A request that Railway did not accept gets a new token and one more try, but only in
    /// the session where it started. After a sign-out and a sign-in with another account, a
    /// retry would send the request, for example a delete, with the token of that account.
    public func permitsRetry(of error: RailwayError, startedIn start: SessionGeneration) -> Bool {
        error.isTokenRejected && start == self
    }

    /// A refresh that Railway refuses ends the sign-in, but only in the session where the
    /// refresh started. A refusal that arrives after **Sign in again** must not end the new
    /// sign-in and close its window.
    public func permitsSessionEnd(after error: OAuthError, startedIn start: SessionGeneration)
        -> Bool
    {
        error == .rejected && start == self
    }
}
