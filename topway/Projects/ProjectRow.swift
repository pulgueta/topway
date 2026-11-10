import SwiftUI
import TopwayCore

// MARK: - Project Row

struct ProjectRow: View {
    let project: Project
    let onAddService: () -> Void
    let onDeleteProject: () async -> Void
    let onServiceTap: (Service) -> Void

    @State private var isExpanded = true
    @State private var isHeaderHovered = false
    @State private var isAddHovered = false
    @State private var isDeleteHovered = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if showDeleteConfirmation {
                // Inline Delete Confirmation
                InlineDeleteConfirmation(
                    title: "Delete Project",
                    message:
                        "Delete \"\(project.name)\"? This will permanently delete all services, deployments, and data.",
                    isLoading: isDeleting,
                    onConfirm: {
                        isDeleting = true
                        Task {
                            await onDeleteProject()
                            isDeleting = false
                            showDeleteConfirmation = false
                        }
                    },
                    onCancel: {
                        showDeleteConfirmation = false
                    }
                )
            } else {
                // Project Header
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
                    Button {
                        onAddService()
                    } label: {
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

                    // Delete Project Button
                    Button {
                        showDeleteConfirmation = true
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
                }

                // Services List
                if isExpanded {
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
        }
        .padding(.vertical, 4)
        .clipped()
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
            ServiceEdge(node: mockService2),
        ]),
        environments: EnvironmentConnection(edges: [])
    )

    VStack {
        ProjectRow(
            project: mockProject,
            onAddService: {},
            onDeleteProject: {},
            onServiceTap: { _ in }
        )
    }
    .padding()
    .frame(width: 320)
}
