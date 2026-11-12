import Foundation

/// Gives a test its own `URLSession` and its own replies. With more than one reply, each
/// request gets the next reply, and the last reply answers all later requests.
struct StubServer {
    let session: URLSession
    private let id = UUID().uuidString

    init(_ replies: StubReply...) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.httpAdditionalHeaders = [StubRegistry.headerName: id]
        session = URLSession(configuration: configuration)
        StubRegistry.register(replies, id: id)
    }

    var requests: [CapturedRequest] {
        StubRegistry.requests(id: id)
    }
}
