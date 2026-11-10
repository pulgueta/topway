import Foundation
import Synchronization

/// Keeps one reply and one request log for each `StubServer`.
/// Parallel tests use different keys, so they cannot see the data of other tests.
enum StubRegistry {
    static let headerName = "X-Topway-Stub-ID"

    private struct Entry {
        var reply: StubReply
        var requests: [CapturedRequest] = []
    }

    private static let entries = Mutex<[String: Entry]>([:])

    static func register(_ reply: StubReply, id: String) {
        entries.withLock { $0[id] = Entry(reply: reply) }
    }

    static func record(_ request: URLRequest) -> StubReply? {
        guard let id = request.value(forHTTPHeaderField: headerName) else { return nil }
        let captured = CapturedRequest(request)
        return entries.withLock { entries in
            entries[id]?.requests.append(captured)
            return entries[id]?.reply
        }
    }

    static func requests(id: String) -> [CapturedRequest] {
        entries.withLock { $0[id]?.requests ?? [] }
    }
}
