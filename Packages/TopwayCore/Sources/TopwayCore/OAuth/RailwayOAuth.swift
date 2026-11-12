import Foundation

/// The fixed values of Sign in with Railway. Railway publishes the endpoints in
/// `https://backboard.railway.com/oauth/.well-known/openid-configuration`.
///
/// Topway is a Native (Public) OAuth app: it has no client secret, and PKCE S256 is
/// necessary. Railway has no revocation endpoint. A user removes the access of Topway in
/// the Railway account settings, on the Apps page.
public enum RailwayOAuth {
    public static let issuer = "https://backboard.railway.com"
    static let authorizationEndpoint = "https://backboard.railway.com/oauth/auth"
    static let tokenEndpoint = "https://backboard.railway.com/oauth/token"

    /// `ASWebAuthenticationSession` gets the redirect to this scheme. Topway does not
    /// register the scheme with the system, so no other app can send it a code.
    public static let callbackScheme = "topway"
    /// Must be the same text as a redirect URI of the OAuth app on Railway.
    public static let redirectURI = "topway://oauth/callback"

    /// - `email` and `profile` are necessary with a workspace scope: without them,
    ///   `me { workspaces }` gives an empty list.
    /// - `offline_access` gives a refresh token, but only with `prompt=consent`.
    /// - `workspace:admin` is the most access that Topway asks for. Railway gives only the
    ///   role that the user has in each workspace that the user selects. Topway deletes
    ///   services and projects and reads the billing usage, and Railway permits these
    ///   actions only to an admin.
    static let scopes = ["openid", "email", "profile", "offline_access", "workspace:admin"]

    /// The Info.plist key that the build fills from `RAILWAY_OAUTH_CLIENT_ID`.
    public static let clientIDInfoKey = "RailwayOAuthClientID"

    /// The client ID from the Info.plist value, or `nil` when the build has none. Then
    /// Topway offers only sample data.
    public static func clientID(fromInfoValue value: Any?) -> String? {
        guard let text = value as? String else { return nil }
        let clientID = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // A build setting that the build did not expand stays as `$(NAME)`.
        guard !clientID.isEmpty, !clientID.hasPrefix("$(") else { return nil }
        return clientID
    }
}
