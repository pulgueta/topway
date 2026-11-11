import Foundation

/// The live `MessageTransport`: a `URLSessionWebSocketTask`.
struct URLSessionMessageTransport: MessageTransport {
    let task: URLSessionWebSocketTask

    func sendText(_ text: String) async throws {
        try await task.send(.string(text))
    }

    func receiveText() async throws -> String {
        switch try await task.receive() {
        case .string(let text): text
        case .data(let data): String(decoding: data, as: UTF8.self)
        @unknown default: ""
        }
    }

    func close(code: Int) {
        task.cancel(
            with: URLSessionWebSocketTask.CloseCode(rawValue: code) ?? .normalClosure, reason: nil)
    }

    var closeCode: Int {
        task.closeCode.rawValue
    }

    var httpStatus: Int? {
        (task.response as? HTTPURLResponse)?.statusCode
    }
}
