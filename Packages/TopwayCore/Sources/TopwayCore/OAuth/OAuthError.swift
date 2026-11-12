import Foundation

/// A failed sign-in or a failed token refresh.
public enum OAuthError: LocalizedError, Equatable {
    /// The user closed the sign-in window. Topway shows no message.
    case cancelled
    /// The user did not give access on the consent page.
    case denied
    /// The callback does not belong to the sign-in that Topway started.
    case invalidCallback
    /// Railway sent an error in the callback, with its description when it has one.
    case authorizationFailed(String?)
    /// Railway did not accept the code or the refresh token. Only a new sign-in can help.
    case rejected
    /// Railway sent a server error or a rate limit. The sign-in stays, because it can pass.
    case serverError(Int)
    case networkError(String)
    /// The answer of Railway has no access token.
    case invalidResponse
    /// The system did not open the sign-in window.
    case cannotOpenWindow

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            nil
        case .denied:
            "Railway did not give access to Topway. To connect, sign in again and accept the access."
        case .invalidCallback:
            "Railway sent a sign-in answer that Topway cannot use. Try again."
        case .authorizationFailed(let description):
            "Railway did not complete the sign-in." + (description.map { " Details: \($0)" } ?? "")
        case .rejected:
            "Railway did not accept the sign-in. Sign in again."
        case .serverError(let status):
            "Railway sent an error. Status code: \(status). Try again later."
        case .networkError(let description):
            "Topway cannot connect to Railway. \(description)"
        case .invalidResponse:
            "Topway cannot read the sign-in answer from Railway. Try again."
        case .cannotOpenWindow:
            "Topway cannot open the sign-in window. Try again."
        }
    }
}
