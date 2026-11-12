import SwiftUI
import TopwayCore

/// The menu bar icon. It shows the overall health of the projects.
struct MenuBarLabel: View {
    let health: HealthSummary

    var body: some View {
        // The menu bar shows only the icon. The title stays the accessibility label.
        Label(accessibilityText, systemImage: symbolName)
    }

    private var symbolName: String {
        switch health.health {
        case .healthy: "tram.fill"
        case .inProgress: "arrow.triangle.2.circlepath"
        case .failing: "exclamationmark.triangle.fill"
        }
    }

    private var accessibilityText: String {
        health.statusDescription.map { "Topway, \($0)" } ?? "Topway"
    }
}

#Preview {
    MenuBarLabel(health: HealthSummary(projects: []))
}
