import Foundation
import Testing
import TopwayCore

struct AuthorizationRequestTests {
    private let request = AuthorizationRequest(
        clientID: "test-client-id", state: "state-1",
        pkce: PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"))

    private func queryItems(of url: URL) throws -> [String: String] {
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = try #require(components.queryItems)
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    @Test("The URL opens the authorization endpoint of Railway")
    func endpoint() {
        #expect(
            request.url.absoluteString.hasPrefix("https://backboard.railway.com/oauth/auth?"))
    }

    @Test("The URL asks for a code with PKCE S256, the state and the redirect URI")
    func parameters() throws {
        let items = try queryItems(of: request.url)

        #expect(items["response_type"] == "code")
        #expect(items["client_id"] == "test-client-id")
        #expect(items["redirect_uri"] == "https://topway.pulgueta.com/oauth/callback")
        #expect(items["state"] == "state-1")
        #expect(items["code_challenge"] == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        #expect(items["code_challenge_method"] == "S256")
        #expect(items["client_secret"] == nil)
    }

    @Test("A refresh token needs offline_access and prompt=consent")
    func refreshTokenParameters() throws {
        let items = try queryItems(of: request.url)

        #expect(items["prompt"] == "consent")
        let scopes = try #require(items["scope"]).split(separator: " ").map(String.init)
        #expect(scopes.contains("offline_access"))
    }

    @Test("The workspace list needs openid, email and profile with a workspace scope")
    func scopes() throws {
        let items = try queryItems(of: request.url)
        let scopes = try #require(items["scope"]).split(separator: " ").map(String.init)

        #expect(scopes == ["openid", "email", "profile", "offline_access", "workspace:admin"])
    }

    @Test("Values are percent-encoded, so a plus sign or a space stays the same text")
    func strictEncoding() throws {
        let unusual = AuthorizationRequest(
            clientID: "a+b c&d", state: "s", pkce: PKCE(verifier: "v"))

        let query = try #require(unusual.url.query(percentEncoded: true))
        #expect(query.contains("client_id=a%2Bb%20c%26d"))
        #expect(try queryItems(of: unusual.url)["client_id"] == "a+b c&d")
    }
}
