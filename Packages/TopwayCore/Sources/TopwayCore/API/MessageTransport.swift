/// Moves the text frames of one WebSocket. `URLSessionMessageTransport` is the live type;
/// tests use scripted frames.
protocol MessageTransport: Sendable {
    func sendText(_ text: String) async throws
    func receiveText() async throws -> String
    func close(code: Int)
    /// The close code of the socket, or 0 while it is open.
    var closeCode: Int { get }
    /// The status of the upgrade response. Status 401 means that Railway refused the token.
    var httpStatus: Int? { get }
}
