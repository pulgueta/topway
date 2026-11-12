/// The answer of the Railway token endpoint. Topway does not use the ID token: the account
/// details come from the GraphQL `me` query.
public struct TokenResponse: Decodable, Sendable, Equatable {
    public let accessToken: String
    /// A refresh answer can have a new refresh token. Railway then does not accept the
    /// earlier one, and a use of it ends the whole authorization.
    public let refreshToken: String?
    /// Seconds. Railway documents one hour.
    public let expiresIn: Int?

    public init(accessToken: String, refreshToken: String?, expiresIn: Int?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
