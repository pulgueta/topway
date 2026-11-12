import SwiftUI

/// The actions of one project, behind a button with a text label.
/// The delete action asks for a confirmation.
struct ProjectMenu: View {
    let projectName: String
    let isMuted: Bool
    let onAddService: () -> Void
    /// `nil` removes the mute action, for example when alerts are off.
    let onToggleMute: (() -> Void)?
    let onRequestDelete: () -> Void

    var body: some View {
        Menu("Manage") {
            Button("Add service", systemImage: "plus") { onAddService() }

            if let onToggleMute {
                Button(
                    isMuted ? "Unmute alerts" : "Mute alerts",
                    systemImage: isMuted ? "bell" : "bell.slash"
                ) {
                    onToggleMute()
                }
            }

            Divider()

            Button("Delete project…", systemImage: "trash", role: .destructive) {
                onRequestDelete()
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .fixedSize()
        .help("Add a service, mute alerts or delete \(projectName).")
        .accessibilityLabel("Manage \(projectName)")
    }
}
