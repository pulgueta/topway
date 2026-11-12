import SwiftUI
import TopwayCore

/// One deployment: its status, its date and its actions.
/// All actions are always visible and have a text label.
struct DeploymentRow: View {
    let deployment: Deployment
    let isRestarting: Bool
    let onRestart: () -> Void
    let onOpenURL: () -> Void
    let onViewLogs: () -> Void

    private var statusColor: Color {
        switch deployment.statusColor {
        case "green": .green
        case "yellow": .yellow
        case "red": .red
        case "purple": .purple
        default: .gray
        }
    }

    var body: some View {
        // `formattedDate` makes date formatters, so the body reads it one time.
        let formattedDate = deployment.formattedDate

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Layout.controlSpacing) {
                // The status text is next to the dot, so the color is not the only sign.
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)

                Text(deployment.statusDisplay)
                    .fontWeight(.medium)

                Spacer(minLength: Layout.controlSpacing)

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Button("View logs") { onViewLogs() }
                    .help("Show the build log and the deploy log of this deployment.")

                if deployment.staticUrl != nil {
                    Button("Open URL") { onOpenURL() }
                        .help("Open the URL of this deployment in your browser.")
                }

                Button(isRestarting ? "Restarting…" : "Restart") { onRestart() }
                    .disabled(isRestarting)
                    .help("Stop this deployment and start it again.")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.leading, 16)
        }
        .padding(.horizontal, Layout.contentInset)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, Layout.contentInset)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(deployment.statusDisplay), \(formattedDate)")
    }
}
