import Foundation
import TopwayCore
import UserNotifications

/// Shows a local notification for each health alert.
enum AlertNotifier {
    /// Shows nothing if the user did not give notification permission.
    static func send(_ alerts: [HealthAlert], isSampleMode: Bool) async throws {
        let center = UNUserNotificationCenter.current()
        guard await center.notificationSettings().authorizationStatus == .authorized else { return }
        for alert in alerts {
            let content = UNMutableNotificationContent()
            content.title = title(for: alert.kind)
            if isSampleMode {
                content.subtitle = "Sample data"
            }
            let service = alert.service
            content.body =
                "\(service.serviceName) in \(service.environmentName) of \(service.projectName)"
            content.sound = .default
            try await center.add(
                UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            )
        }
    }

    private static func title(for kind: AlertKind) -> String {
        switch kind {
        case .failed: "Deployment failed"
        case .crashed: "Service crashed"
        case .recovered: "Service recovered"
        }
    }
}
