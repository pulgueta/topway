import Foundation

/// Sends the token requests of Sign in with Railway. Topway is a public client: each request
/// has the client ID in the body and no client secret, as Railway requires for a Native app.
public struct RailwayOAuthClient: Sendable {
    private let session: URLSession
    private let now: @Sendable () -> Date

    /// - Parameter now: Gives the time that a token answer arrives. Tests replace it.
    public init(session: URLSession = .shared, now: @escaping @Sendable () -> Date = { .now }) {
        self.session = session
        self.now = now
    }

    /// Exchanges the code of the callback for tokens. The verifier proves that this app
    /// started the sign-in.
    public func exchange(code: String, verifier: String, clientID: String)
        async throws(OAuthError) -> OAuthTokens
    {
        let response = try await send([
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": RailwayOAuth.redirectURI,
            "client_id": clientID,
            "code_verifier": verifier,
        ])
        return OAuthTokens(response, receivedAt: now())
    }

    /// Gets a new access token. Save the result before the next refresh: Railway can rotate
    /// the refresh token, and a use of an earlier refresh token ends the authorization.
    public func refresh(_ tokens: OAuthTokens, clientID: String)
        async throws(OAuthError) -> OAuthTokens
    {
        guard let refreshToken = tokens.refreshToken else { throw .rejected }
        let response = try await send([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID,
        ])
        return OAuthTokens(response, receivedAt: now(), previous: tokens)
    }

    private func send(_ fields: KeyValuePairs<String, String>)
        async throws(OAuthError) -> TokenResponse
    {
        guard let url = URL(string: RailwayOAuth.tokenEndpoint) else { throw .invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(FormEncoding.encode(fields).utf8)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw .cancelled
            }
            throw .networkError(error.localizedDescription)
        }

        guard let status = (response as? HTTPURLResponse)?.statusCode else {
            throw .invalidResponse
        }
        switch status {
        case 200..<300:
            guard let answer = try? JSONDecoder().decode(TokenResponse.self, from: data),
                !answer.accessToken.isEmpty
            else { throw .invalidResponse }
            return answer
        case 400, 401:
            // For example `invalid_grant`: the code or the refresh token is used, expired
            // or revoked. Topway never sends the body to the user, because it can have details
            // of the request.
            throw .rejected
        default:
            throw .serverError(status)
        }
    }
}
