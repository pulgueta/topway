import SwiftUI

// MARK: - Service Row

struct ServiceRow: View {
    let service: Service
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var isDeleteHovered = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 4) {
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
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            
            // Delete button (only visible on hover)
            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isDeleteHovered ? .red : .secondary)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isDeleteHovered ? Color.red.opacity(0.1) : Color.clear)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isDeleteHovered = hovering
                }
            }
            .opacity(isHovered || isDeleteHovered ? 1 : 0)
            .help("Delete service")
        }
        .padding(.leading, 20)
        .confirmationDialog(
            "Delete Service",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(service.name)\"? This will remove all deployments and data associated with this service.")
        }
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

struct ProjectRow: View {
    let project: Project
    let onAddService: () -> Void
    let onDeleteProject: () -> Void
    let onServiceTap: (Service) -> Void
    let onDeleteService: (Service) -> Void
    
    @State private var isExpanded = true
    @State private var isHeaderHovered = false
    @State private var isAddHovered = false
    @State private var isDeleteHovered = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Project Header
            HStack(spacing: 0) {
                // Expand/Collapse + Project Name
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHeaderHovered = hovering
                    }
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
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isAddHovered = hovering
                    }
                }
                .help("Add a new service")
                
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
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isDeleteHovered = hovering
                    }
                }
                .help("Delete project")
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
                                },
                                onDelete: {
                                    onDeleteService(service)
                                }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog(
            "Delete Project",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDeleteProject()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(project.name)\"? This action cannot be undone and will permanently delete all services, deployments, and data associated with this project.")
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
            onDeleteProject: {},
            onServiceTap: { _ in },
            onDeleteService: { _ in }
        )
    }
    .padding()
    .frame(width: 320)
}
