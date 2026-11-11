import Foundation
import Synchronization

@testable import TopwayCore

/// A `MessageTransport` that gives scripted frames in order, with no network.
/// When the frames end, `receiveText` waits until `close` is called, as a quiet socket does.
final class ScriptedTransport: MessageTransport {
    enum Frame: Sendable {
        case text(String)
        case failure(URLError)
    }

    private struct State {
        var frames: [Frame]
        var sent: [String] = []
        var closeCode: Int?
        var receiver: CheckedContinuation<String, any Error>?
        var closeWaiters: [CheckedContinuation<Int, Never>] = []
    }

    private let state: Mutex<State>
    let httpStatus: Int?

    init(_ frames: [Frame], httpStatus: Int? = 101) {
        state = Mutex(State(frames: frames))
        self.httpStatus = httpStatus
    }

    var sent: [String] {
        state.withLock { $0.sent }
    }

    var closeCode: Int {
        state.withLock { $0.closeCode ?? 0 }
    }

    /// Returns the close code when the client closes the transport.
    func waitForClose() async -> Int {
        await withCheckedContinuation { continuation in
            state.withLock { state in
                if let code = state.closeCode {
                    continuation.resume(returning: code)
                } else {
                    state.closeWaiters.append(continuation)
                }
            }
        }
    }

    func sendText(_ text: String) async throws {
        try state.withLock { state in
            guard state.closeCode == nil else { throw URLError(.cancelled) }
            state.sent.append(text)
        }
    }

    func receiveText() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            state.withLock { state in
                if state.closeCode != nil {
                    continuation.resume(throwing: URLError(.cancelled))
                } else if state.frames.isEmpty {
                    state.receiver = continuation
                } else {
                    switch state.frames.removeFirst() {
                    case .text(let text): continuation.resume(returning: text)
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    func close(code: Int) {
        state.withLock { state in
            guard state.closeCode == nil else { return }
            state.closeCode = code
            state.receiver?.resume(throwing: URLError(.cancelled))
            state.receiver = nil
            for waiter in state.closeWaiters {
                waiter.resume(returning: code)
            }
            state.closeWaiters = []
        }
    }
}
