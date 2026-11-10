struct StubReply: Sendable {
    var status = 200
    var headers: [String: String] = [:]
    var body: String
}
