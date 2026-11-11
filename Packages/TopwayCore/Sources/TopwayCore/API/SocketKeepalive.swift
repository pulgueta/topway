import Synchronization

/// Finds a half-open socket. Every 20 seconds, it checks for a message since the last tick.
/// If there is one, it sends a ping, and the server must answer with a pong. If there is
/// none, the socket is dropped. So a socket with no message for 20 seconds after a ping is
/// dropped, at most 40 seconds after the last message.
///
/// The class is `Sendable` because a `Mutex` keeps its state.
final class SocketKeepalive: Sendable {
    static let interval = Duration.seconds(20)

    private struct State {
        /// The socket is new, so it counts as an answer.
        var isMessageReceived = true
        var isDropped = false
    }

    private let state = Mutex(State())

    var isDropped: Bool {
        state.withLock { $0.isDropped }
    }

    /// Call this for each message from the server, not only for a pong.
    func messageReceived() {
        state.withLock { $0.isMessageReceived = true }
    }

    /// Returns when the socket is dropped. Throws when `sleep` or `sendPing` throws.
    func run(
        sleep: @Sendable (Duration) async throws -> Void, sendPing: () async throws -> Void
    ) async throws {
        while true {
            try await sleep(Self.interval)
            let isAnswered = state.withLock { state in
                defer { state.isMessageReceived = false }
                return state.isMessageReceived
            }
            guard isAnswered else {
                state.withLock { $0.isDropped = true }
                return
            }
            try await sendPing()
        }
    }
}
