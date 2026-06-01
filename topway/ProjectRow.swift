import SwiftUI

// MARK: - Service Row

@MainActor
struct ServiceRow: View {
    let service: Service
    let onTap: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)

                Text(service.name)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .opacity(isHovered ? 1 : 0.5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .padding(.leading, 20)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var backgroundColor: Color {
        if isPressed {
            return Color.accentColor.opacity(0.2)
        } else if isHovered {
            return Color.primary.opacity(0.06)
        }
        return Color.clear
    }
}

// MARK: - Project Row

@MainActor
struct ProjectRow: View {
    let project: Project
    let onAddService: () -> Void
    let onRequestDelete: () -> Void
    let onServiceTap: (Service) -> Void

    @State private var isExpanded = true
    @State private var isHeaderHovered = false
    @State private var isAddHovered = false
    @State private var isDeleteHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            projectHeader

            if isExpanded {
                servicesList
            }
        }
        .padding(.vertical, 4)
        .clipped()
    }

    // MARK: - Header

    private var projectHeader: some View {
        HStack(spacing: 0) {
            // Expand/Collapse + Project Name
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 12)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)

                    Text(project.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHeaderHovered ? Color.primary.opacity(0.06) : Color.clear)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHeaderHovered = hovering
            }

            Spacer()

            // Add Service Button
            Button(action: onAddService) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isAddHovered ? .primary : .secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isAddHovered ? Color.primary.opacity(0.1) : Color.clear)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isAddHovered = hovering
            }
            .help("Add service")
            .accessibilityLabel("Add service")

            // Delete Project Button
            Button {
                onRequestDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isDeleteHovered ? .red : .secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isDeleteHovered ? Color.red.opacity(0.1) : Color.clear)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isDeleteHovered = hovering
            }
            .help("Delete project")
            .accessibilityLabel("Delete project")
        }
    }

    // MARK: - Services

    private var servicesList: some View {
        VStack(alignment: .leading, spacing: 2) {
            if project.serviceList.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)

                    Text("No services")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .padding(.leading, 28)
                .padding(.vertical, 4)
            } else {
                ForEach(project.serviceList) { service in
                    ServiceRow(
                        service: service,
                        onTap: {
                            onServiceTap(service)
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    let mockService = Service(id: "1", name: "web-app")
    let mockService2 = Service(id: "2", name: "api-server")
    let mockProject = Project(
        id: "1",
        name: "My Project",
        services: ServiceConnection(edges: [
            ServiceEdge(node: mockService),
            ServiceEdge(node: mockService2)
        ]),
        environments: EnvironmentConnection(edges: [])
    )

    VStack {
        ProjectRow(
            project: mockProject,
            onAddService: {},
            onRequestDelete: {},
            onServiceTap: { _ in }
        )
    }
    .padding()
    .frame(width: 320)
}
