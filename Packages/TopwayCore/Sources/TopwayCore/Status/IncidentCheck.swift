import Foundation

/// Says when to ask Railway for its platform status again.
public enum IncidentCheck {
    /// The seconds between two checks. An incident does not start or end in seconds.
    static let interval: TimeInterval = 300

    /// `true` with no earlier check, or when the last check is 5 minutes old or more.
    public static func isDue(lastCheck: Date?, now: Date) -> Bool {
        guard let lastCheck else { return true }
        return now.timeIntervalSince(lastCheck) >= interval
    }
}
