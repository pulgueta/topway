import Foundation
import Testing
import TopwayCore

struct AuthorizationCallbackTests {
    private func url(_ text: String) throws -> URL {
        try #require(URL(string: text))
    }

    @Test("A callback with the same state gives the code")
    func code() throws {
        let callback = try url(
            "https://topway.pulgueta.com/oauth/callback?code=abc123&state=s1"
                + "&iss=https%3A%2F%2Fbackboard.railway.com")

        #expect(try AuthorizationCallback.code(in: callback, state: "s1") == "abc123")
    }

    @Test("A callback with no issuer gives the code")
    func noIssuer() throws {
        let callback = try url("https://topway.pulgueta.com/oauth/callback?code=abc123&state=s1")

        #expect(try AuthorizationCallback.code(in: callback, state: "s1") == "abc123")
    }

    @Test("The redirect URI that Railway gets is an address that the check accepts")
    func redirectURI() throws {
        let callback = try url("\(RailwayOAuth.redirectURI)?code=abc123&state=s1")

        #expect(try AuthorizationCallback.code(in: callback, state: "s1") == "abc123")
    }

    @Test(
        "A callback that does not match the request gives no code",
        arguments: [
            "https://topway.pulgueta.com/oauth/callback?code=abc123&state=other",
            "https://topway.pulgueta.com/oauth/callback?code=abc123",
            "https://topway.pulgueta.com/oauth/callback?state=s1",
            "https://topway.pulgueta.com/oauth/callback?code=&state=s1",
            "https://topway.pulgueta.com/oauth/callback?code=abc123&state=s1"
                + "&iss=https%3A%2F%2Fevil.example.com",
        ])
    func invalid(text: String) throws {
        let callback = try url(text)

        #expect(throws: OAuthError.invalidCallback) {
            try AuthorizationCallback.code(in: callback, state: "s1")
        }
    }

    @Test(
        "A callback to another address gives no code",
        arguments: [
            "topway://oauth/callback?code=abc123&state=s1",
            "http://topway.pulgueta.com/oauth/callback?code=abc123&state=s1",
            "https://evil.example.com/oauth/callback?code=abc123&state=s1",
            "https://topway.pulgueta.com.evil.example/oauth/callback?code=abc123&state=s1",
            "https://pulgueta.com/oauth/callback?code=abc123&state=s1",
            "https://topway.pulgueta.com/oauth/other?code=abc123&state=s1",
            "https://topway.pulgueta.com/oauth/callback/?code=abc123&state=s1",
            "https://topway.pulgueta.com:8443/oauth/callback?code=abc123&state=s1",
            "https://user@topway.pulgueta.com/oauth/callback?code=abc123&state=s1",
            "https://topway.pulgueta.com:/oauth/callback?code=abc123&state=s1",
            "https://topway.pulgueta.com/oauth/callback?code=abc123&state=s1#other",
            "https://topway.pulgueta.com/oauth/callback#?code=abc123&state=s1",
        ])
    func otherAddress(text: String) throws {
        let callback = try url(text)

        #expect(throws: OAuthError.invalidCallback) {
            try AuthorizationCallback.code(in: callback, state: "s1")
        }
    }

    @Test("A user who does not give access gets the denied error")
    func denied() throws {
        let callback = try url(
            "https://topway.pulgueta.com/oauth/callback?error=access_denied&state=s1")

        #expect(throws: OAuthError.denied) {
            try AuthorizationCallback.code(in: callback, state: "s1")
        }
    }

    @Test("Another error keeps the description of Railway")
    func otherError() throws {
        let callback = try url(
            "https://topway.pulgueta.com/oauth/callback?error=invalid_scope"
                + "&error_description=Bad%20scope&state=s1")

        #expect(throws: OAuthError.authorizationFailed("Bad scope")) {
            try AuthorizationCallback.code(in: callback, state: "s1")
        }
    }

    @Test("An error with a different state is not trusted")
    func errorWithOtherState() throws {
        let callback = try url(
            "https://topway.pulgueta.com/oauth/callback?error=access_denied&state=other")

        #expect(throws: OAuthError.invalidCallback) {
            try AuthorizationCallback.code(in: callback, state: "s1")
        }
    }

    @Test("Only the cancelled error shows no message")
    func messages() {
        #expect(OAuthError.cancelled.errorDescription == nil)
        let others: [OAuthError] = [
            .denied, .invalidCallback, .authorizationFailed(nil), .rejected, .serverError(500),
            .networkError("Offline"), .invalidResponse, .cannotOpenWindow, .requestRefused(nil),
        ]
        for error in others {
            #expect(error.errorDescription != nil, "\(error)")
        }
    }
}
