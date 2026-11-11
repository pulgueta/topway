import Foundation

public struct Deployment: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    let status: String
    public let staticUrl: String?
    let createdAt: String

    public var statusDisplay: String {
        switch status.lowercased() {
        case "success": "Running"
        case "building": "Building"
        case "deploying": "Deploying"
        case "failed": "Failed"
        case "crashed": "Crashed"
        case "removed": "Removed"
        case "sleeping": "Sleeping"
        case "queued": "Queued"
        case "waiting": "Waiting"
        case "skipped": "Skipped"
        default: status.capitalized
        }
    }

    public var statusColor: String {
        switch status.lowercased() {
        case "success": "green"
        case "building", "deploying", "queued", "waiting": "yellow"
        case "failed", "crashed": "red"
        case "removed", "skipped": "gray"
        case "sleeping": "purple"
        default: "gray"
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
