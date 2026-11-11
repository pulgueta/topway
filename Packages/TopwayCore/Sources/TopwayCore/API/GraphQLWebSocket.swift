import Foundation

/// Sends one GraphQL subscription over a `URLSessionWebSocketTask`.
/// The protocol rules are in `GraphQLSubscription`; this type only moves the messages.
struct GraphQLWebSocket: Sendable {
    private static let url = URL(string: "wss://backboard.railway.com/graphql/v2")
    private static let operationId = "1"

    let session: URLSession

    /// Cancel the consumer task to stop. The socket then sends `complete` and closes.
    func subscribe<Payload: Decodable & Sendable>(
        _ request: GraphQLRequest, token: String, as _: Payload.Type
    ) -> AsyncThrowingStream<SubscriptionEvent<Payload>, any Error> {
        AsyncThrowingStream { continuation in
            guard let url = Self.url else {
                continuation.finish(throwing: RailwayError.invalidURL)
                return
            }
            var upgrade = URLRequest(url: url)
            upgrade.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            upgrade.setValue(
                GraphQLSubscription<Payload>.subprotocol,
                forHTTPHeaderField: "Sec-WebSocket-Protocol")
            let socket = session.webSocketTask(with: upgrade)

            let task = Task {
                await withTaskCancellationHandler {
                    await run(socket, request: request, continuation: continuation)
                } onCancel: {
                    let complete = GraphQLClientMessage.complete(id: Self.operationId).text
                    socket.send(.string(complete)) { _ in
                        socket.cancel(with: .normalClosure, reason: nil)
                    }
                }
            }
            continuation.onTermination = { _ in task.cancel() }
            socket.resume()
        }
    }

    private func run<Payload: Decodable & Sendable>(
        _ socket: URLSessionWebSocketTask, request: GraphQLRequest,
        continuation: AsyncThrowingStream<SubscriptionEvent<Payload>, any Error>.Continuation
    ) async {
        var subscription = GraphQLSubscription<Payload>(id: Self.operationId, request: request)
        let keepalive = SocketKeepalive()
        // The protocol ping gets its pong from the GraphQL server, so it shows that the server
        // still works. A WebSocket ping frame can get an answer from a proxy only.
        let watchdog = Task {
            do {
                try await keepalive.run(sleep: { try await Task.sleep(for: $0) }) {
                    try await socket.send(.string(GraphQLClientMessage.ping.text))
                }
                // No answer, so the socket is half-open. Closing it makes `receive` fail.
                socket.cancel(with: .goingAway, reason: nil)
            } catch {
                // The stream ended, or the ping send failed. A failed send also makes
                // `receive` fail, and the catch below reports that error.
            }
        }
        defer { watchdog.cancel() }
        do {
            try await socket.send(.string(GraphQLClientMessage.connectionInit.text))
            while true {
                let message = try await socket.receive()
                keepalive.messageReceived()
                let text =
                    switch message {
                    case .string(let text): text
                    case .data(let data): String(decoding: data, as: UTF8.self)
                    @unknown default: ""
                    }
                switch try subscription.receive(text) {
                case .connected(let message):
                    try await socket.send(.string(message.text))
                    continuation.yield(.connected)
                case .reply(let message):
                    try await socket.send(.string(message.text))
                case .payload(let payload):
                    continuation.yield(.payload(payload))
                case .completed:
                    socket.cancel(with: .normalClosure, reason: nil)
                    continuation.finish()
                    return
                case .ignore:
                    break
                }
            }
        } catch {
            // The cancellation handler closes the socket, so `receive` fails. That is no error.
            guard !Task.isCancelled else {
                continuation.finish()
                return
            }
            socket.cancel(with: .normalClosure, reason: nil)
            // A dropped socket is a network failure, so the log stream connects again.
            let failure = keepalive.isDropped ? URLError(.timedOut) : error
            continuation.finish(
                throwing: GraphQLSubscription<Payload>.error(
                    for: failure, closeCode: socket.closeCode.rawValue,
                    httpStatus: (socket.response as? HTTPURLResponse)?.statusCode))
        }
    }
}
