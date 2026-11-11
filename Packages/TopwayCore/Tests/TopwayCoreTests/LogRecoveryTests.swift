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
        #expect(LogRecovery(after: error, wasLive: true) == .reconnect)
    }

    @Test("A socket that cannot connect falls back to polling", arguments: socketErrors)
    func cannotConnect(error: RailwayError) {
        #expect(LogRecovery(after: error, wasLive: false) == .poll)
    }

    @Test(
        "An answer from Railway stops the stream, because polling gets the same answer",
        arguments: [
            RailwayError.unauthorized, .graphQLError("Deployment not found"),
            .rateLimited(retryAfter: nil), .httpStatus(500, message: nil), .cancelled,
        ])
    func railwayAnswer(error: RailwayError) {
        #expect(LogRecovery(after: error, wasLive: true) == .fail)
        #expect(LogRecovery(after: error, wasLive: false) == .fail)
    }
}
