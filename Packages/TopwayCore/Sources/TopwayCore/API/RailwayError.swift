import Foundation

public enum RailwayError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case graphQLError(String)
    case unauthorized
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .graphQLError(let message):
            return "API error: \(message)"
        case .unauthorized:
            return "Invalid API token"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
