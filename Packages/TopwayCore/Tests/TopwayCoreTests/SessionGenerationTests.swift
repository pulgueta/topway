import Foundation
import Testing
import TopwayCore

struct SessionGenerationTests {
    @Test(
        "A new sign-in, a sign-out and sample mode make the results of earlier requests stale",
        arguments: [
            SessionGeneration.Event.signInStarted, .signedOut, .sampleModeStarted,
        ])
    func staleAfterEvent(event: SessionGeneration.Event) {
        var current = SessionGeneration()
        let started = current

        current.record(event)

        #expect(started != current)
    }

    @Test("A token refresh keeps the same session, so its results stay current")
    func refreshKeepsSession() {
        var current = SessionGeneration()
        let started = current

        current.record(.tokensRefreshed)

        #expect(started == current)
    }

    @Test("Each event gives a different generation")
    func eachEventIsNew() {
        var current = SessionGeneration()
        current.record(.signInStarted)
        let first = current

        current.record(.signInStarted)

        #expect(first != current)
    }

    @Test("A rejected token gets one retry only in the session where the request started")
    func retryInSameSession() {
        var current = SessionGeneration()
        let started = current

        #expect(current.permitsRetry(of: .unauthorized, startedIn: started))

        current.record(.tokensRefreshed)
        #expect(current.permitsRetry(of: .unauthorized, startedIn: started))
    }

    @Test(
        "After a sign-out, a new sign-in or sample mode, a late rejection gets no retry",
        arguments: [
            SessionGeneration.Event.signInStarted, .signedOut, .sampleModeStarted,
        ])
    func noRetryInLaterSession(event: SessionGeneration.Event) {
        var current = SessionGeneration()
        let started = current

        current.record(event)

        #expect(!current.permitsRetry(of: .unauthorized, startedIn: started))
    }

    @Test("Only a rejected token gets a retry")
    func noRetryForOtherErrors() {
        let current = SessionGeneration()
        let others: [RailwayError] = [
            .networkError(URLError(.notConnectedToInternet)), .graphQLError("Not found"),
            .httpStatus(500, message: nil), .rateLimited(retryAfter: nil), .cancelled, .unknown,
        ]

        for error in others {
            #expect(!current.permitsRetry(of: error, startedIn: current), "\(error)")
        }
    }
}
