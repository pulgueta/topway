import SwiftUI
import TopwayCore

/// One deployment: its status, its date and its actions.
/// The actions that the user does most are always visible and have a text label. The rare
/// actions that a deployment permits are in its **Manage** menu.
struct DeploymentRow: View {
    let deployment: Deployment
    let isRestarting: Bool
    /// An action of the Manage menu runs for this deployment.
    var isBusy = false
    let onRestart: () -> Void
    /// The actions of the Manage menu: rollback, cancel and remove.
    var onAction: (DeploymentAction) -> Void = { _ in }
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
        // Each row has the same buttons, so each accessibility label names the deployment.
        let name = "\(deployment.statusDisplay), \(formattedDate)"

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
                    .accessibilityLabel("View logs, \(name)")
                    .accessibilityInputLabels(["View logs"])

                if deployment.staticUrl != nil {
                    Button("Open URL") { onOpenURL() }
                        .help("Open the URL of this deployment in your browser.")
                        .accessibilityLabel("Open URL, \(name)")
                        .accessibilityInputLabels(["Open URL"])
                }

                Button(isRestarting ? "Restarting…" : "Restart") { onRestart() }
                    .disabled(isRestarting)
                    .help("Stop this deployment and start it again.")
                    .accessibilityLabel("\(isRestarting ? "Restarting" : "Restart"), \(name)")
                    .accessibilityInputLabels(["Restart"])

                manageMenu(name: name)
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
        .accessibilityLabel(name)
    }

    /// Shows only the actions that the deployment permits. With no action, it does not show.
    @ViewBuilder
    private func manageMenu(name: String) -> some View {
        let actions = deployment.availableActions
        if !actions.isEmpty {
            Menu(isBusy ? "Working…" : "Manage") {
                if actions.contains(.rollback) {
                    Button("Roll back…", systemImage: "arrow.uturn.backward") {
                        onAction(.rollback)
                    }
                }

                if actions.contains(.cancel) {
                    Button("Cancel deployment…", systemImage: "xmark.circle") {
                        onAction(.cancel)
                    }
                }

                if actions.contains(.remove) {
                    if actions.count > 1 {
                        Divider()
                    }

                    Button("Remove deployment…", systemImage: "trash", role: .destructive) {
                        onAction(.remove)
                    }
                }
            }
            .fixedSize()
            .disabled(isBusy)
            .help("Roll back, cancel or remove this deployment.")
            .accessibilityLabel("\(isBusy ? "Working" : "Manage"), \(name)")
            .accessibilityInputLabels(["Manage"])
        }
    }
}
