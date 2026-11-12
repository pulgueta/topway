import Foundation

public enum RailwayError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case graphQLError(String)
    case unauthorized
    case rateLimited(retryAfter: String?)
    case httpStatus(Int, message: String?)
    case cancelled
    case unknown

    /// Makes the error for a failed transfer. A cancelled request is not a failure to report.
    public init(transportFailure error: any Error) {
        if error is CancellationError || (error as? URLError)?.code == .cancelled {
            self = .cancelled
        } else {
            self = .networkError(error)
        }
    }

    /// Makes the error for the GraphQL errors of a response or of a socket message.
    /// Railway answers a request that has a bad token with status 200 and the message
    /// "Not Authorized", so that message is the same error as an HTTP 401.
    init(graphQLErrors errors: [GraphQLError]) {
        if errors.contains(where: { $0.message.lowercased() == "not authorized" }) {
            self = .unauthorized
        } else {
            self = .graphQLError(errors.map(\.message).joined(separator: ", "))
        }
    }

    /// Railway did not accept the token. A retry with the same token fails again.
    public var isTokenRejected: Bool {
        if case .unauthorized = self { true } else { false }
    }

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API URL is not valid."
        case .networkError(let error):
            return "Topway cannot connect to Railway. \(error.localizedDescription)"
        case .decodingError(let error):
            return "Topway cannot read the response from Railway. \(error.localizedDescription)"
        case .graphQLError(let message):
            return "Railway sent an error: \(message)"
        case .unauthorized:
            return "Railway did not accept your sign-in."
        case .rateLimited(let retryAfter):
            guard let seconds = retryAfter.flatMap({ Int($0) }) else {
                return "Railway got too many requests. Try again later."
            }
            let unit = seconds == 1 ? "second" : "seconds"
            return "Railway got too many requests. Try again in \(seconds) \(unit)."
        case .httpStatus(let status, let message):
            let text = "Railway sent an error. Status code: \(status)."
            return message.map { "\(text) Details: \($0)" } ?? text
        case .cancelled:
            return nil
        case .unknown:
            return "An error occurred. Try again."
        }
    }
}
