import Foundation
import Synchronization

/// Keeps the replies and one request log for each `StubServer`.
/// Parallel tests use different keys, so they cannot see the data of other tests.
enum StubRegistry {
    static let headerName = "X-Topway-Stub-ID"

    private struct Entry {
        /// One reply for each request, in order. The last reply answers all later requests.
        var replies: [StubReply]
        var requests: [CapturedRequest] = []
    }

    private static let entries = Mutex<[String: Entry]>([:])

    static func register(_ replies: [StubReply], id: String) {
        entries.withLock { $0[id] = Entry(replies: replies) }
    }

    static func record(_ request: URLRequest) -> StubReply? {
        guard let id = request.value(forHTTPHeaderField: headerName) else { return nil }
        let captured = CapturedRequest(request)
        return entries.withLock { entries in
            guard var entry = entries[id] else { return nil }
            entry.requests.append(captured)
            entries[id] = entry
            return entry.replies[min(entry.requests.count, entry.replies.count) - 1]
        }
    }

    static func requests(id: String) -> [CapturedRequest] {
        entries.withLock { $0[id]?.requests ?? [] }
    }
}
