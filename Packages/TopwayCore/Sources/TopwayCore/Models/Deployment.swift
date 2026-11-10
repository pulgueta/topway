import Foundation

public struct Deployment: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    let status: String
    public let staticUrl: String?
    let createdAt: String

    public var statusDisplay: String {
        switch status.lowercased() {
        case "success": return "Running"
        case "building": return "Building"
        case "deploying": return "Deploying"
        case "failed": return "Failed"
        case "crashed": return "Crashed"
        case "removed": return "Removed"
        case "sleeping": return "Sleeping"
        default: return status.capitalized
        }
    }

    public var statusColor: String {
        switch status.lowercased() {
        case "success": return "green"
        case "building", "deploying": return "yellow"
        case "failed", "crashed": return "red"
        case "removed": return "gray"
        case "sleeping": return "purple"
        default: return "gray"
        }
    }

    public var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        return createdAt
    }
}
