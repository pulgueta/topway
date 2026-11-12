import SwiftUI

/// The actions of one service, behind a button with a text label.
/// Redeploy and delete ask for a confirmation.
struct ServiceMenu: View {
    let serviceName: String
    let isRedeploying: Bool
    let onShowSettings: () -> Void
    let onRedeploy: () -> Void
    let onRequestDelete: () -> Void

    var body: some View {
        Menu("Manage") {
            Button("Settings", systemImage: "gearshape") { onShowSettings() }

            Button("Redeploy", systemImage: "arrow.triangle.2.circlepath") { onRedeploy() }
                .disabled(isRedeploying)

            Divider()

            Button("Delete service…", systemImage: "trash", role: .destructive) {
                onRequestDelete()
            }
        }
        .buttonStyle(.glass)
        .fixedSize()
        .help("Change the settings of \(serviceName), redeploy it or delete it.")
        .accessibilityLabel("Manage \(serviceName)")
        .accessibilityInputLabels(["Manage", "Manage \(serviceName)"])
    }
}
