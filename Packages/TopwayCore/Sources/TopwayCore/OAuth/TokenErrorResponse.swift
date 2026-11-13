/// The error answer of the token endpoint (RFC 6749, section 5.2). Topway reads only the
/// error code. It never shows `error_description` or the rest of the body.
struct TokenErrorResponse: Decodable, Sendable {
    let error: String

    /// Only `invalid_grant` says that the code or the refresh token is used, expired or
    /// revoked, so that only a new sign-in can help.
    var isGrantRefused: Bool {
        error == "invalid_grant"
    }
}
