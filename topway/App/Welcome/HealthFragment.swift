import SwiftUI
import TopwayCore

/// The copy for the health page: the menu bar with the Topway icon in each state, and the
/// meaning of each icon.
struct HealthFragment: View {
    let states: [HealthSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(states, id: \.health) { summary in
                MenuBarStrip(health: summary, caption: caption(for: summary.health))
            }
        }
    }

    private func caption(for health: Health) -> LocalizedStringKey {
        switch health {
        case .healthy: "Healthy"
        case .inProgress: "In progress"
        case .failing: "Failed"
        }
    }
}
