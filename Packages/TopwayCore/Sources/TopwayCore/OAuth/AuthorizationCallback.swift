import Foundation

/// Reads the redirect that Railway sends to `https://topway.pulgueta.com/oauth/callback` after
/// the consent page.
public enum AuthorizationCallback {
    /// The authorization code of the callback.
    ///
    /// The text of the callback before the query must be the same as
    /// `RailwayOAuth.redirectURI`, and the callback must have no fragment. It must have the
    /// `state` of the request, also when it has an error, so a page that Topway did not open
    /// cannot give it a code or an error. When Railway adds `iss` (RFC 9207), it must be the
    /// Railway issuer.
    public static func code(in url: URL, state: String) throws(OAuthError) -> String {
        let text = url.absoluteString
        let endpoint = text.firstIndex(of: "?").map { String(text[..<$0]) } ?? text
        guard endpoint == RailwayOAuth.redirectURI, url.fragment() == nil,
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
