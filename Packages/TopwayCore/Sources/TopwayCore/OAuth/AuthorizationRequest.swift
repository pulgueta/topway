import Foundation

/// One sign-in attempt. Keep it until the callback arrives: the callback must have the same
/// `state`, and the code exchange needs the PKCE verifier.
public struct AuthorizationRequest: Sendable {
    public let clientID: String
    public let state: String
    public let pkce: PKCE

    public init(clientID: String, state: String = randomState(), pkce: PKCE = .random()) {
        self.clientID = clientID
        self.state = state
        self.pkce = pkce
    }

    /// 32 random bytes, URL safe. The callback must give it back unchanged.
    public static func randomState() -> String {
        Data.random(count: 32).base64URLEncoded
    }

    /// The page that the sign-in window opens. `prompt=consent` always shows the consent
    /// page of Railway: Railway gives a refresh token only then, and the user can select the
    /// workspaces again.
    public var url: URL {
        var components = URLComponents(string: RailwayOAuth.authorizationEndpoint)
        components?.percentEncodedQuery = FormEncoding.encode([
            "response_type": "code",
            "client_id": clientID,
            "redirect_uri": RailwayOAuth.redirectURI,
            "scope": RailwayOAuth.scopes.joined(separator: " "),
            "state": state,
            "code_challenge": pkce.challenge,
            "code_challenge_method": "S256",
            "prompt": "consent",
        ])
        // The endpoint is a constant, so the URL is always valid.
        return components?.url ?? URL(filePath: "/")
    }
}
