import Foundation
import Synchronization
import Testing

@testable import TopwayCore

/// A log stream can run longer than one access token. Each socket connect and each poll asks
/// for the token again, so a reconnect after a refresh sends the new token.
struct LogTokenTests {
    /// Gives "t1", then "t2", and so on.
    final class TokenSource: Sendable {
        private let count = Mutex(0)

        @Sendable func next() -> String {
            let number = count.withLock { count in
                count += 1
                return count
            }
            return "t\(number)"
        }
    }

    /// Opens a socket that fails before Railway acknowledges it, and keeps the token of each
    /// upgrade request.
    final class RecordingConnector: Sendable {
        private let tokens = Mutex<[String]>([])

        var authorizations: [String] {
            tokens.withLock { $0 }
        }

        var socket: GraphQLWebSocket {
            GraphQLWebSocket(
                connect: { request in
                    let header = request.value(forHTTPHeaderField: "Authorization") ?? ""
                    self.tokens.withLock { $0.append(header) }
                    return ScriptedTransport([.failure(URLError(.cannotConnectToHost))])
                },
                sleep: { _ in try await Task.sleep(for: .seconds(3_600)) })
        }
    }

    @Test("The socket and each poll get the token from the provider at the time they start")
    func tokenForEachConnectAndPoll() async throws {
        let server = StubServer(StubReply(body: RailwayClientRecoveryTests.lines))
        let connector = RecordingConnector()
        let tokens = TokenSource()
        let client = RailwayClient(
            session: server.session, sleep: StubSleep(stopAt: 2).sleep, socket: connector.socket)

        for try await _ in client.logs(.deploy, deploymentId: "d1", token: tokens.next) {}

        #expect(connector.authorizations == ["Bearer t1"])
        #expect(server.requests.map(\.authorization) == ["Bearer t2", "Bearer t3"])
    }
}
