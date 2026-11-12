import Foundation
import Testing
import TopwayCore

struct RailwayOAuthClientTests {
    private static let answer = """
        {"access_token":"a1","expires_in":3600,"refresh_token":"r1","token_type":"Bearer"}
        """
    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func client(_ server: StubServer) -> RailwayOAuthClient {
        let now = now
        return RailwayOAuthClient(session: server.session, now: { now })
    }

    @Test("The code exchange sends the code and the verifier, with no secret")
    func exchangeRequest() async throws {
        let server = StubServer(StubReply(body: Self.answer))

        let tokens = try await client(server).exchange(
            code: "code-1", verifier: "verifier-1", clientID: "test-client-id")

        #expect(tokens == OAuthTokens(accessToken: "a1", refreshToken: "r1", expiresAt: now + 3600))
        let request = try #require(server.requests.first)
        #expect(request.url?.absoluteString == "https://backboard.railway.com/oauth/token")
        #expect(request.method == "POST")
        #expect(request.contentType == "application/x-www-form-urlencoded")
        #expect(request.authorization == nil)
        #expect(
            request.form == [
                "grant_type": "authorization_code",
                "code": "code-1",
                "redirect_uri": "topway://oauth/callback",
                "client_id": "test-client-id",
                "code_verifier": "verifier-1",
            ])
    }

    @Test("A refresh sends the refresh token and the client ID, with no secret")
    func refreshRequest() async throws {
        let server = StubServer(
            StubReply(body: #"{"access_token":"a2","expires_in":3600,"refresh_token":"r2"}"#))
        let earlier = OAuthTokens(accessToken: "a1", refreshToken: "r1", expiresAt: now)

        let tokens = try await client(server).refresh(earlier, clientID: "test-client-id")

        #expect(tokens == OAuthTokens(accessToken: "a2", refreshToken: "r2", expiresAt: now + 3600))
        let request = try #require(server.requests.first)
        #expect(request.authorization == nil)
        #expect(
            request.form == [
                "grant_type": "refresh_token",
                "refresh_token": "r1",
                "client_id": "test-client-id",
            ])
    }

    @Test("Tokens with no refresh token cannot refresh, and no request goes to Railway")
    func noRefreshToken() async throws {
        let server = StubServer(StubReply(body: Self.answer))
        let earlier = OAuthTokens(accessToken: "a1", refreshToken: nil, expiresAt: now)

        await #expect(throws: OAuthError.rejected) {
            try await client(server).refresh(earlier, clientID: "test-client-id")
        }
        #expect(server.requests.isEmpty)
    }

    @Test("Railway refuses the grant (RFC 6749, 5.2): the user must sign in again")
    func rejected() async throws {
        let server = StubServer(
            StubReply(
                status: 400,
                body: #"{"error":"invalid_grant","error_description":"grant request is invalid"}"#))
        let earlier = OAuthTokens(accessToken: "a1", refreshToken: "r1", expiresAt: now)

        await #expect(throws: OAuthError.rejected) {
            try await client(server).refresh(earlier, clientID: "test-client-id")
        }
    }

    @Test(
        "Another refused token request keeps the sign-in and gives the error code",
        arguments: [
            (400, #"{"error":"invalid_request"}"#, "invalid_request"),
            (401, #"{"error":"invalid_client"}"#, "invalid_client"),
            (400, #"{"error":"unauthorized_client"}"#, "unauthorized_client"),
            (400, "not json", nil),
        ] as [(Int, String, String?)])
    func refused(status: Int, body: String, code: String?) async throws {
        let server = StubServer(StubReply(status: status, body: body))
        let earlier = OAuthTokens(accessToken: "a1", refreshToken: "r1", expiresAt: now)

        await #expect(throws: OAuthError.requestRefused(code)) {
            try await client(server).refresh(earlier, clientID: "test-client-id")
        }
    }

    @Test(
        "A server error or a rate limit keeps the sign-in, because it can pass",
        arguments: [429, 500, 503])
    func serverError(status: Int) async throws {
        let server = StubServer(StubReply(status: status, body: "{}"))
        let earlier = OAuthTokens(accessToken: "a1", refreshToken: "r1", expiresAt: now)

        await #expect(throws: OAuthError.serverError(status)) {
            try await client(server).refresh(earlier, clientID: "test-client-id")
        }
    }

    @Test("A network failure is a network error, not a rejected sign-in")
    func networkFailure() async throws {
        let server = StubServer(StubReply(body: "", failure: URLError(.notConnectedToInternet)))

        do {
            _ = try await client(server).exchange(
                code: "c", verifier: "v", clientID: "test-client-id")
            Issue.record("The exchange did not fail")
        } catch {
            guard case .networkError = error else {
                Issue.record("Wrong error: \(error)")
                return
            }
        }
    }

    @Test("An answer with no access token cannot be used")
    func invalidAnswer() async throws {
        let server = StubServer(StubReply(body: #"{"token_type":"Bearer"}"#))

        await #expect(throws: OAuthError.invalidResponse) {
            try await client(server).exchange(code: "c", verifier: "v", clientID: "test-client-id")
        }
    }
}
