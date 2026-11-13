import CryptoKit
import Foundation

/// Proof Key for Code Exchange (RFC 7636) with the S256 method. The verifier stays in
/// Topway and goes only to the token endpoint. The challenge goes in the authorization URL.
public struct PKCE: Sendable, Equatable {
    public let verifier: String
    public let challenge: String

    public init(verifier: String) {
        self.verifier = verifier
        challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded
    }

    /// A verifier from 32 random bytes: 43 characters, as RFC 7636 recommends.
    public static func random() -> PKCE {
        PKCE(verifier: Data.random(count: 32).base64URLEncoded)
    }
}
