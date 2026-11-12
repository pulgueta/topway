import Foundation

public struct Deployment: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    let status: String
    public let staticUrl: String?
    let createdAt: String
    /// Railway says if a rollback to this deployment is possible. `nil` when the request
    /// did not ask for it.
    let canRollback: Bool?

    init(
        id: String, status: String, staticUrl: String?, createdAt: String,
        canRollback: Bool? = nil
    ) {
        self.id = id
        self.status = status
        self.staticUrl = staticUrl
        self.createdAt = createdAt
        self.canRollback = canRollback
    }

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

    /// The log that the logs screen shows first. A deployment that builds, waits to deploy
    /// or failed shows its build log. Other deployments show their deploy log.
    public var defaultLogKind: LogKind {
        isBuildRunning || status.uppercased() == "FAILED" ? .build : .deploy
    }

    /// The deployment builds or waits to deploy, so its build log can get more lines.
    var isBuildRunning: Bool {
        switch status.uppercased() {
        case "BUILDING", "QUEUED", "WAITING", "INITIALIZING", "NEEDS_APPROVAL": true
        default: false
        }
    }

    /// The actions of the Manage menu of this deployment. A build or a deploy in progress
    /// has only Cancel. Rollback shows when Railway says that it is possible. Remove shows
    /// for a deployment that holds the service: it runs, it crashed or it sleeps.
    public var availableActions: [DeploymentAction] {
        switch status.uppercased() {
        case "BUILDING", "DEPLOYING", "QUEUED", "WAITING", "INITIALIZING", "NEEDS_APPROVAL":
            return [.cancel]
        case "REMOVING":
            return []
        case "SUCCESS", "CRASHED", "SLEEPING":
            return canRollback == true ? [.rollback, .remove] : [.remove]
        default:
            return canRollback == true ? [.rollback] : []
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
