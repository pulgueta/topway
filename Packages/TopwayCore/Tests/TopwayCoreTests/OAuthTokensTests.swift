import Foundation
import Testing
import TopwayCore

struct OAuthTokensTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    @Test("A token answer gives the expiry date from expires_in")
    func expiry() {
        let tokens = OAuthTokens(
            TokenResponse(accessToken: "a1", refreshToken: "r1", expiresIn: 3600),
            receivedAt: now)

        #expect(tokens.accessToken == "a1")
        #expect(tokens.refreshToken == "r1")
        #expect(tokens.expiresAt == now.addingTimeInterval(3600))
    }

    @Test("With no expires_in, the token expires after one hour, as Railway documents")
    func defaultExpiry() {
        let tokens = OAuthTokens(
            TokenResponse(accessToken: "a1", refreshToken: nil, expiresIn: nil), receivedAt: now)

        #expect(tokens.expiresAt == now.addingTimeInterval(3600))
    }

    @Test("A refresh answer with a new refresh token replaces the earlier one")
    func rotatedRefreshToken() {
        let earlier = OAuthTokens(accessToken: "a1", refreshToken: "r1", expiresAt: now)

        let tokens = OAuthTokens(
            TokenResponse(accessToken: "a2", refreshToken: "r2", expiresIn: 3600),
            receivedAt: now, previous: earlier)

        #expect(tokens.refreshToken == "r2")
    }

    @Test("A refresh answer with no refresh token keeps the earlier one")
    func keptRefreshToken() {
        let earlier = OAuthTokens(accessToken: "a1", refreshToken: "r1", expiresAt: now)

        let tokens = OAuthTokens(
            TokenResponse(accessToken: "a2", refreshToken: nil, expiresIn: 3600),
            receivedAt: now, previous: earlier)

        #expect(tokens.accessToken == "a2")
        #expect(tokens.refreshToken == "r1")
    }

    @Test(
        "A token needs a refresh 5 minutes before it expires",
        arguments: [
            (-3600.0, false), (-301.0, false), (-300.0, true), (0.0, true), (60.0, true),
        ])
    func needsRefresh(offset: TimeInterval, expected: Bool) {
        let tokens = OAuthTokens(accessToken: "a1", refreshToken: "r1", expiresAt: now)

        #expect(tokens.needsRefresh(at: now.addingTimeInterval(offset)) == expected)
    }

    @Test("The Keychain text gives the same tokens back")
    func keychainRoundTrip() throws {
        let tokens = OAuthTokens(accessToken: "a1", refreshToken: "r1", expiresAt: now)

        let text = try #require(tokens.keychainValue)
        #expect(OAuthTokens(keychainValue: text) == tokens)
    }

    @Test("Keychain text that is not tokens gives nil", arguments: ["", "token", "{}"])
    func badKeychainValue(text: String) {
        #expect(OAuthTokens(keychainValue: text) == nil)
    }

    @Test("The token answer of Railway decodes")
    func decodeAnswer() throws {
        let json = """
            {"access_token":"a1","expires_in":3600,"id_token":"i1","refresh_token":"r1",
             "scope":"openid email profile offline_access","token_type":"Bearer"}
            """

        let response = try JSONDecoder().decode(TokenResponse.self, from: Data(json.utf8))

        #expect(response == TokenResponse(accessToken: "a1", refreshToken: "r1", expiresIn: 3600))
    }
}
