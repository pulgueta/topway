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
}
