import Foundation
import Testing
import TopwayCore

struct RecoveryRulesTests {
    @Test("A rejected token offers Settings first, then sample data, and no retry")
    func rejectedToken() {
        let actions = RecoveryRules.actions(isTokenRejected: true, isSampleMode: false)

        #expect(actions == [.openSettings, .useSampleData])
    }

    @Test("Other failures offer a retry first, then Settings")
    func otherFailure() {
        let actions = RecoveryRules.actions(isTokenRejected: false, isSampleMode: false)

        #expect(actions == [.retry, .openSettings])
    }

    @Test(
        "Sample mode offers only a retry, because it has no token and no settings to change",
        arguments: [true, false])
    func sampleMode(isTokenRejected: Bool) {
        let actions = RecoveryRules.actions(isTokenRejected: isTokenRejected, isSampleMode: true)

        #expect(actions == [.retry])
    }

    @Test("Only the unauthorized error means that Railway rejected the token")
    func tokenRejectedErrors() {
        #expect(RailwayError.unauthorized.isTokenRejected)

        let otherErrors: [RailwayError] = [
            .invalidURL,
            .networkError(URLError(.notConnectedToInternet)),
            .decodingError(URLError(.cannotParseResponse)),
            .graphQLError("Not found"),
            .rateLimited(retryAfter: nil),
            .httpStatus(500, message: nil),
            .cancelled,
            .unknown,
        ]
        for error in otherErrors {
            #expect(!error.isTokenRejected, "\(error)")
        }
    }
}
