import Synchronization

/// Replaces `Task.sleep`, so tests do not wait. It records each duration.
/// The call number `stopAt` throws `CancellationError`, as a cancelled task does.
final class StubSleep: Sendable {
    private let stopAt: Int
    private let log = Mutex<[Duration]>([])

    init(stopAt: Int) {
        self.stopAt = stopAt
    }

    var durations: [Duration] {
        log.withLock { $0 }
    }

    @Sendable func sleep(_ duration: Duration) throws {
        let count = log.withLock { log in
            log.append(duration)
            return log.count
        }
        if count >= stopAt {
            throw CancellationError()
        }
    }
}
