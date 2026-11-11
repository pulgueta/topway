import Synchronization
import Testing

@testable import TopwayCore

struct SocketKeepaliveTests {
    @Test("With no message after a ping, the next tick drops the socket")
    func noPong() async throws {
        let keepalive = SocketKeepalive()
        let sleep = StubSleep(stopAt: 10)
        let pings = Mutex(0)

        try await keepalive.run(sleep: sleep.sleep) {
            pings.withLock { $0 += 1 }
        }

        #expect(keepalive.isDropped)
        #expect(pings.withLock { $0 } == 1)
        #expect(sleep.durations == [.seconds(20), .seconds(20)])
    }

    @Test("A pong after each ping keeps the socket live")
    func pong() async throws {
        let keepalive = SocketKeepalive()
        let sleep = StubSleep(stopAt: 3)
        let pings = Mutex(0)

        await #expect(throws: CancellationError.self) {
            try await keepalive.run(sleep: sleep.sleep) {
                pings.withLock { $0 += 1 }
                keepalive.messageReceived()
            }
        }

        #expect(!keepalive.isDropped)
        #expect(pings.withLock { $0 } == 2)
    }
}
