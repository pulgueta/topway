import Foundation
import Synchronization

@testable import TopwayCore

/// Opens a new `ScriptedTransport` for each connect. `make` gets the connect number, from 1.
final class ScriptedConnector: Sendable {
    private let make: @Sendable (Int) -> ScriptedTransport
    private let count = Mutex(0)

    init(make: @escaping @Sendable (Int) -> ScriptedTransport) {
        self.make = make
    }

    var connects: Int {
        count.withLock { $0 }
    }

    /// A socket whose keepalive does not act during a test.
    var socket: GraphQLWebSocket {
        GraphQLWebSocket(
            connect: { _ in
                self.make(
                    self.count.withLock { count in
                        count += 1
                        return count
                    })
            },
            sleep: { _ in try await Task.sleep(for: .seconds(3_600)) })
    }
}
