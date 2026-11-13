import Foundation

/// Reads the redirect that Railway sends to `https://topway.pulgueta.com/oauth/callback` after
/// the consent page.
public enum AuthorizationCallback {
    /// The authorization code of the callback.
    ///
    /// The callback must go to `RailwayOAuth.redirectURI`: the scheme `https`, the same host and
    /// path, and no port or user name. It must have the `state` of the request, also when it
    /// has an error, so a page that Topway did not open cannot give it a code or an error. When
    /// Railway adds `iss` (RFC 9207), it must be the Railway issuer.
    public static func code(in url: URL, state: String) throws(OAuthError) -> String {
        guard url.scheme == "https", url.host() == RailwayOAuth.callbackHost,
            url.port == nil, url.user() == nil, url.password() == nil,
            url.path() == RailwayOAuth.callbackPath,
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { throw .invalidCallback }

        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        guard value("state") == state else { throw .invalidCallback }
        if let error = value("error") {
            throw error == "access_denied"
                ? .denied : .authorizationFailed(value("error_description"))
        }
        if let issuer = value("iss"), issuer != RailwayOAuth.issuer {
            throw .invalidCallback
        }
        guard let code = value("code"), !code.isEmpty else { throw .invalidCallback }
        return code
    }
}
