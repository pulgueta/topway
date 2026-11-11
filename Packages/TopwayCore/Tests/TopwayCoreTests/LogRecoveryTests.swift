import Foundation
import Testing

@testable import TopwayCore

struct LogRecoveryTests {
    private static let socketErrors: [RailwayError] = [
        .networkError(URLError(.networkConnectionLost)),
        .decodingError(URLError(.cannotDecodeContentData)),
        .unknown,
    ]

    @Test("A socket that drops after it was live connects again", arguments: socketErrors)
    func dropAfterLive(error: RailwayError) {
        var recovery = LogRecovery()
        recovery.connected()

        #expect(recovery.step(after: error) == .reconnect(after: .seconds(2)))
    }

    @Test("A socket that cannot connect falls back to polling", arguments: socketErrors)
    func cannotConnect(error: RailwayError) {
        var recovery = LogRecovery()

        #expect(recovery.step(after: error) == .poll)
    }

    @Test(
        "An answer from Railway stops the stream, because polling gets the same answer",
        arguments: [
            RailwayError.unauthorized, .graphQLError("Deployment not found"),
            .rateLimited(retryAfter: nil), .httpStatus(500, message: nil), .cancelled,
        ])
    func railwayAnswer(error: RailwayError) {
        var live = LogRecovery()
        live.connected()
        var notLive = LogRecovery()

        #expect(live.step(after: error) == .fail)
        #expect(notLive.step(after: error) == .fail)
    }

    @Test("After 3 live passes with no payload, a network error falls back to polling")
    func emptyPassesThenPoll() {
        var recovery = LogRecovery()
        var steps: [LogRecovery.Step] = []
        for _ in 1...3 {
            recovery.connected()
            steps.append(recovery.step(after: .networkError(URLError(.networkConnectionLost))))
        }

        #expect(steps.last == .poll)
        #expect(steps.dropLast().allSatisfy { if case .reconnect = $0 { true } else { false } })
    }

    @Test(
        "After 3 live passes with no payload, a decoding or unknown error stops the stream",
        arguments: [RailwayError.decodingError(URLError(.cannotDecodeContentData)), .unknown])
    func emptyPassesThenFail(error: RailwayError) {
        var recovery = LogRecovery()
        var steps: [LogRecovery.Step] = []
        for _ in 1...3 {
            recovery.connected()
            steps.append(recovery.step(after: error))
        }

        #expect(steps.last == .fail)
    }

    @Test("A payload resets the count of empty live passes")
    func payloadResetsCount() {
        var recovery = LogRecovery()
        for _ in 1...2 {
            recovery.connected()
            _ = recovery.step(after: .unknown)
        }
        recovery.connected()
        recovery.payloadReceived()
        _ = recovery.step(after: .unknown)

        recovery.connected()
        if case .reconnect = recovery.step(after: .unknown) {
        } else {
            Issue.record("Expected a reconnect after the payload reset the count")
        }
    }
}
