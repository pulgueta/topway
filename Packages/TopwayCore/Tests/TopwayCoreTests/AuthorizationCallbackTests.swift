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
            "topway://oauth/callback?code=abc123&state=s1&iss=https%3A%2F%2Fbackboard.railway.com")

        #expect(try AuthorizationCallback.code(in: callback, state: "s1") == "abc123")
    }

    @Test("A callback with no issuer gives the code")
    func noIssuer() throws {
        let callback = try url("topway://oauth/callback?code=abc123&state=s1")

        #expect(try AuthorizationCallback.code(in: callback, state: "s1") == "abc123")
    }

    @Test(
        "A callback that does not match the request gives no code",
        arguments: [
            "topway://oauth/callback?code=abc123&state=other",
            "topway://oauth/callback?code=abc123",
            "topway://oauth/callback?state=s1",
            "topway://oauth/callback?code=&state=s1",
            "topway://oauth/other?code=abc123&state=s1",
            "other://oauth/callback?code=abc123&state=s1",
            "topway://oauth/callback?code=abc123&state=s1&iss=https%3A%2F%2Fevil.example.com",
        ])
    func invalid(text: String) throws {
        let callback = try url(text)

        #expect(throws: OAuthError.invalidCallback) {
            try AuthorizationCallback.code(in: callback, state: "s1")
        }
    }

    @Test("A user who does not give access gets the denied error")
    func denied() throws {
        let callback = try url("topway://oauth/callback?error=access_denied&state=s1")

        #expect(throws: OAuthError.denied) {
            try AuthorizationCallback.code(in: callback, state: "s1")
        }
    }

    @Test("Another error keeps the description of Railway")
    func otherError() throws {
        let callback = try url(
            "topway://oauth/callback?error=invalid_scope&error_description=Bad%20scope&state=s1")

        #expect(throws: OAuthError.authorizationFailed("Bad scope")) {
            try AuthorizationCallback.code(in: callback, state: "s1")
        }
    }

    @Test("An error with a different state is not trusted")
    func errorWithOtherState() throws {
        let callback = try url("topway://oauth/callback?error=access_denied&state=other")

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
