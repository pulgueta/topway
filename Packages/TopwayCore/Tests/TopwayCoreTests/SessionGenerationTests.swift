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
}
