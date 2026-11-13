import Testing
import TopwayCore

struct RailwayOAuthTests {
    @Test(
        "The client ID comes from the Info.plist value, and an empty value gives no sign-in",
        arguments: [
            ("test-client-id", "test-client-id"),
            ("  test-client-id\n", "test-client-id"),
            ("", nil),
            ("   ", nil),
            ("$(RAILWAY_OAUTH_CLIENT_ID)", nil),
        ] as [(String, String?)])
    func clientID(value: String, expected: String?) {
        #expect(RailwayOAuth.clientID(fromInfoValue: value) == expected)
    }

    @Test("A missing or non-text Info.plist value gives no sign-in")
    func missingClientID() {
        #expect(RailwayOAuth.clientID(fromInfoValue: nil) == nil)
        #expect(RailwayOAuth.clientID(fromInfoValue: 42) == nil)
    }
}
