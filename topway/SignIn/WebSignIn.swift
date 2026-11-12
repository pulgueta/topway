import AppKit
import AuthenticationServices
import TopwayCore

/// Shows the Railway sign-in page in a system browser window and gives the callback URL.
///
/// The session is not ephemeral: it shares the cookies of the default browser. A user who is
/// signed in to Railway in the browser then sees only the consent page, and a sign-in link
/// from an email opens in the same browser. An ephemeral session would ask for the Railway
/// password at each sign-in, and an email link could not complete it.
///
/// `ASWebAuthenticationSession` gets the redirect to `topway://` itself, so Topway registers
/// no URL scheme and runs no local server.
final class WebSignIn: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let anchor: ASPresentationAnchor
    private var session: ASWebAuthenticationSession?

    private init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    /// - Throws: `OAuthError.cancelled` when the user closes the window.
    static func callbackURL(for url: URL) async throws -> URL {
        // The window of the control that started the sign-in: the menu bar window or Settings.
        let signIn = WebSignIn(anchor: NSApp.keyWindow ?? ASPresentationAnchor())
        // The menu bar window is a panel that does not activate the app, so the sign-in
        // window could open behind other windows.
        NSApp.activate()
        return try await signIn.start(url)
    }

    private func start(_ url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url, callback: .customScheme(RailwayOAuth.callbackScheme)
            ) { @Sendable callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                    continuation.resume(throwing: OAuthError.cancelled)
                } else {
                    continuation.resume(throwing: error ?? OAuthError.invalidCallback)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            // When the session does not start, it does not call the completion handler.
            if !session.start() {
                continuation.resume(throwing: OAuthError.cannotOpenWindow)
            }
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor
    }
}
