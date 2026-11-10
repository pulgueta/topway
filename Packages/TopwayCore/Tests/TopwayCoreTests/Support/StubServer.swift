import Foundation

/// Gives a test its own `URLSession` and its own reply.
struct StubServer {
    let session: URLSession
    private let id = UUID().uuidString

    init(_ reply: StubReply) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.httpAdditionalHeaders = [StubRegistry.headerName: id]
        session = URLSession(configuration: configuration)
        StubRegistry.register(reply, id: id)
    }

    var requests: [CapturedRequest] {
        StubRegistry.requests(id: id)
    }
}
