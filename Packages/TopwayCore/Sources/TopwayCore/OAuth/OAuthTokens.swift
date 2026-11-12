import Foundation

/// The tokens of Sign in with Railway. Topway keeps them in the Keychain as one item, so the
/// access token and the refresh token always change together.
public struct OAuthTokens: Codable, Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresAt: Date

    /// Topway gets a new access token this time before it expires, so a request does not
    /// fail while it is on the way.
    static let refreshMargin: TimeInterval = 5 * 60
    /// Railway documents that an access token expires after one hour.
    private static let defaultLifetime: TimeInterval = 60 * 60

    public init(accessToken: String, refreshToken: String?, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    /// - Parameter previous: The tokens before a refresh. A refresh answer with no refresh
    ///   token keeps the earlier one.
    public init(_ response: TokenResponse, receivedAt now: Date, previous: OAuthTokens? = nil) {
        self.init(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken ?? previous?.refreshToken,
            expiresAt: now.addingTimeInterval(
                response.expiresIn.map(TimeInterval.init) ?? Self.defaultLifetime))
    }

    public func needsRefresh(at date: Date) -> Bool {
        date >= expiresAt.addingTimeInterval(-Self.refreshMargin)
    }

    // MARK: - Keychain

    /// JSON text for `KeychainStore`.
    public var keychainValue: String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return (try? encoder.encode(self)).map { String(decoding: $0, as: UTF8.self) }
    }

    /// `nil` when the text is not saved tokens.
    public init?(keychainValue: String) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let tokens = try? decoder.decode(Self.self, from: Data(keychainValue.utf8)) else {
            return nil
        }
        self = tokens
    }
}
