import Foundation

/// Sends one GraphQL subscription over a `MessageTransport`.
/// The protocol rules are in `GraphQLSubscription`; this type only moves the messages.
struct GraphQLWebSocket: Sendable {
    private static let url = URL(string: "wss://backboard.railway.com/graphql/v2")
    private static let operationId = "1"
    private static let normalClosure = 1_000
    private static let goingAway = 1_001

    private let connect: @Sendable (URLRequest) -> any MessageTransport
    private let sleep: @Sendable (Duration) async throws -> Void

    /// Connects with `URLSessionWebSocketTask`.
    init(session: URLSession) {
        self.init(
            connect: { request in
                let task = session.webSocketTask(with: request)
                task.resume()
                return URLSessionMessageTransport(task: task)
            },
            sleep: { try await Task.sleep(for: $0) })
    }

    /// - Parameters:
    ///   - connect: Opens a transport for the upgrade request.
    ///   - sleep: Waits between keepalive checks.
    init(
        connect: @escaping @Sendable (URLRequest) -> any MessageTransport,
        sleep: @escaping @Sendable (Duration) async throws -> Void
    ) {
        self.connect = connect
        self.sleep = sleep
    }

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
            let transport = connect(upgrade)

            let task = Task {
                await withTaskCancellationHandler {
                    await run(transport, request: request, continuation: continuation)
                } onCancel: {
                    let complete = GraphQLClientMessage.complete(id: Self.operationId).text
                    Task {
                        do {
                            try await transport.sendText(complete)
                        } catch {
                            // The socket closes in the next step, so a failed send changes nothing.
                        }
                        transport.close(code: Self.normalClosure)
                    }
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run<Payload: Decodable & Sendable>(
        _ transport: any MessageTransport, request: GraphQLRequest,
        continuation: AsyncThrowingStream<SubscriptionEvent<Payload>, any Error>.Continuation
    ) async {
        var subscription = GraphQLSubscription<Payload>(id: Self.operationId, request: request)
        let keepalive = SocketKeepalive()
        // The protocol ping gets its pong from the GraphQL server, so it shows that the server
        // still works. A WebSocket ping frame can get an answer from a proxy only.
        let watchdog = Task {
            do {
                try await keepalive.run(sleep: sleep) {
                    try await transport.sendText(GraphQLClientMessage.ping.text)
                }
                // No answer, so the socket is half-open. Closing it makes `receive` fail.
                transport.close(code: Self.goingAway)
            } catch {
                // The stream ended, or the ping send failed. A failed send also makes
                // `receive` fail, and the catch below reports that error.
            }
        }
        defer { watchdog.cancel() }
        do {
            try await transport.sendText(GraphQLClientMessage.connectionInit.text)
            while true {
                let text = try await transport.receiveText()
                keepalive.messageReceived()
                switch try subscription.receive(text) {
                case .connected(let message):
                    try await transport.sendText(message.text)
                    continuation.yield(.connected)
                case .reply(let message):
                    try await transport.sendText(message.text)
                case .payload(let payload):
                    continuation.yield(.payload(payload))
                case .completed:
                    transport.close(code: Self.normalClosure)
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
            transport.close(code: Self.normalClosure)
            // A dropped socket is a network failure, so the log stream connects again.
            let failure = keepalive.isDropped ? URLError(.timedOut) : error
            continuation.finish(
                throwing: GraphQLSubscription<Payload>.error(
                    for: failure, closeCode: transport.closeCode,
                    httpStatus: transport.httpStatus))
        }
    }
}
