import SwiftUI
import TopwayCore

/// One project: its name, the Manage menu, and its services.
struct ProjectRow: View {
    let project: Project
    var isMuted = false
    let onAddService: () -> Void
    let onRequestDelete: () -> Void
    let onServiceTap: (Service) -> Void
    /// `nil` removes the mute action, for example when alerts are off.
    var onToggleMute: (() -> Void)?

    @State private var isExpanded = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                disclosureButton

                ProjectMenu(
                    projectName: project.name,
                    isMuted: isMuted,
                    onAddService: onAddService,
                    onToggleMute: onToggleMute,
                    onRequestDelete: onRequestDelete
                )
            }

            if isExpanded {
                services
            }
        }
    }

    private var disclosureButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .screenChange) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 12)

                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)

                Text(project.name)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if isMuted {
                    Image(systemName: "bell.slash.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help("Alerts are muted for this project.")
                }
            }
        }
        .buttonStyle(RowButtonStyle())
        .accessibilityLabel(isMuted ? "\(project.name), alerts muted" : project.name)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint("Shows or hides the services of this project.")
    }

    private var services: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(project.serviceList) { service in
                ServiceRow(service: service) { onServiceTap(service) }
            }

            if project.serviceList.isEmpty {
                Text("This project has no services.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }

            Button("Add service", systemImage: "plus") { onAddService() }
                .buttonStyle(RowButtonStyle())
                .foregroundStyle(.secondary)
                .help(
                    "Add a service to \(project.name) from a GitHub repository or a Docker image.")
        }
        .padding(.leading, 18)
    }
}

#Preview {
    let web = Service(id: "1", name: "web-app")
    let api = Service(id: "2", name: "api-server")
    let project = Project(
        id: "1",
        name: "My Project",
        services: ServiceConnection(edges: [ServiceEdge(node: web), ServiceEdge(node: api)]),
        environments: EnvironmentConnection(edges: [])
    )

    ProjectRow(
        project: project,
        isMuted: true,
        onAddService: {},
        onRequestDelete: {},
        onServiceTap: { _ in },
        onToggleMute: {}
    )
    .padding()
    .frame(width: Layout.windowWidth)
}
