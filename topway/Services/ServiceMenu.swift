import SwiftUI

/// The actions of one service, behind a button with a text label.
/// Each action asks for a confirmation.
struct ServiceMenu: View {
    let serviceName: String
    let isRedeploying: Bool
    let onRedeploy: () -> Void
    let onRequestDelete: () -> Void

    var body: some View {
        Menu("Manage") {
            Button("Redeploy", systemImage: "arrow.triangle.2.circlepath") { onRedeploy() }
                .disabled(isRedeploying)

            Divider()

            Button("Delete service…", systemImage: "trash", role: .destructive) {
                onRequestDelete()
            }
        }
        .buttonStyle(.glass)
        .fixedSize()
        .help("Redeploy or delete \(serviceName).")
        .accessibilityLabel("Manage \(serviceName)")
    }
}
