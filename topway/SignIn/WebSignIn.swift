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
/// `ASWebAuthenticationSession` gets the redirect to `RailwayOAuth.redirectURI` itself, so
/// Topway registers no URL scheme and runs no local server. The callback is HTTPS: Associated
/// Domains (`webcredentials:topway.pulgueta.com`) give it only to an app with the Topway
/// signature.
final class WebSignIn: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let anchor: ASPresentationAnchor
    private var session: ASWebAuthenticationSession?
    /// The waiting sign-in. `finish` resumes it one time: from the session, or from `cancel`.
    private var continuation: CheckedContinuation<URL, any Error>?

    /// Uses the window of the control that starts the sign-in: the menu bar window or
    /// Settings.
    override init() {
        anchor = NSApp.keyWindow ?? ASPresentationAnchor()
    }

    /// - Throws: `OAuthError.cancelled` when the user closes the window or `cancel()` runs.
    func callbackURL(for url: URL) async throws -> URL {
        // The menu bar window is a panel that does not activate the app, so the sign-in
        // window could open behind other windows.
        NSApp.activate()
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = ASWebAuthenticationSession(
                url: url,
                callback: .https(host: RailwayOAuth.callbackHost, path: RailwayOAuth.callbackPath)
            ) { @Sendable callbackURL, error in
                let result: Result<URL, any Error>
                if let callbackURL {
                    result = .success(callbackURL)
                } else if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                    result = .failure(OAuthError.cancelled)
                } else {
                    result = .failure(error ?? OAuthError.invalidCallback)
                }
                Task { @MainActor in self.finish(result) }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            // When the session does not start, it does not call the completion handler.
            if !session.start() {
                finish(.failure(OAuthError.cannotOpenWindow))
            }
        }
    }

    /// Closes the sign-in window, for example after a sign-out or a selection of sample data.
    func cancel() {
        session?.cancel()
        finish(.failure(OAuthError.cancelled))
    }

    private func finish(_ result: Result<URL, any Error>) {
        guard let continuation else { return }
        self.continuation = nil
        session = nil
        continuation.resume(with: result)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor
    }
}
