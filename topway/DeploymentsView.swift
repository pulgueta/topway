import SwiftUI

struct DeploymentsView: View {
    @Environment(AppState.self) private var appState
    
    let service: Service
    let project: Project
    let environmentId: String
    let onDismiss: () -> Void
    let onDeleteService: () async -> Void
    
    @State private var deployments: [Deployment] = []
    @State private var isLoading = true
    @State private var isRedeploying = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var restartingDeploymentId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Service Info
            serviceInfoView
            
            Divider()
            
            // Content
            contentView
            
            Divider()
            
            // Footer
            footerView
        }
        .task {
            await loadDeployments()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            BackButton { onDismiss() }
            
            Spacer()
            
            Text("Deployments")
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            // Refresh button
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                    .frame(width: 24, height: 24)
            } else {
                IconButton(
                    icon: "arrow.clockwise",
                    help: "Refresh"
                ) {
                    Task { await loadDeployments() }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Service Info
    
    private var serviceInfoView: some View {
        HStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 12))
                .foregroundStyle(.blue)
            
            Text(service.name)
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            Text(project.name)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            VStack(spacing: 12) {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                Text("Loading deployments...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if deployments.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
                
                VStack(spacing: 4) {
                    Text("No Deployments")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Deploy your service to see deployment history here.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Button {
                    Task { await triggerRedeploy() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                        Text("Deploy Now")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isRedeploying)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(deployments) { deployment in
                        DeploymentRow(
                            deployment: deployment,
                            isRestarting: restartingDeploymentId == deployment.id,
                            onRestart: {
                                Task { await restartDeployment(deployment) }
                            },
                            onOpenURL: {
                                if let urlString = deployment.staticUrl,
                                   let url = URL(string: "https://\(urlString)") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        VStack(spacing: 0) {
            if showDeleteConfirmation {
                // Inline delete confirmation
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                        
                        Text("Delete \"\(service.name)\"?")
                            .font(.system(size: 12, weight: .medium))
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        Button {
                            showDeleteConfirmation = false
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            isDeleting = true
                            Task {
                                await onDeleteService()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if isDeleting {
                                    ProgressView()
                                        .controlSize(.small)
                                        .scaleEffect(0.6)
                                }
                                Text("Delete")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.red)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeleting)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.05))
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            } else {
                HStack {
                    Text("\(deployments.count) deployment\(deployments.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                    
                    // Delete service button
                    DeleteServiceButton {
                        showDeleteConfirmation = true
                    }
                    
                    // Redeploy button
                    RedeployButton(isLoading: isRedeploying) {
                        Task { await triggerRedeploy() }
                    }
                    .disabled(isRedeploying)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadDeployments() async {
        isLoading = true
        deployments = await appState.fetchDeployments(
            projectId: project.id,
            environmentId: environmentId,
            serviceId: service.id
        )
        isLoading = false
    }
    
    private func restartDeployment(_ deployment: Deployment) async {
        restartingDeploymentId = deployment.id
        _ = await appState.restartDeployment(deploymentId: deployment.id)
        restartingDeploymentId = nil
        // Reload deployments to see updated status
        await loadDeployments()
    }
    
    private func triggerRedeploy() async {
        isRedeploying = true
        _ = await appState.redeployService(
            environmentId: environmentId,
            serviceId: service.id
        )
        isRedeploying = false
        // Reload deployments to see the new one
        await loadDeployments()
    }
}

// MARK: - Deployment Row

struct DeploymentRow: View {
    let deployment: Deployment
    let isRestarting: Bool
    let onRestart: () -> Void
    let onOpenURL: () -> Void
    
    @State private var isHovered = false
    
    private var statusColor: Color {
        switch deployment.statusColor {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        case "purple": return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                // Status
                Text(deployment.statusDisplay)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                
                // Date
                Text(deployment.formattedDate)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 4) {
                // Open URL (if available)
                if deployment.staticUrl != nil {
                    IconButton(icon: "link", help: "Open URL") {
                        onOpenURL()
                    }
                }
                
                // Restart button
                if isRestarting {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                        .frame(width: 22, height: 22)
                } else {
                    IconButton(icon: "arrow.clockwise", help: "Restart deployment") {
                        onRestart()
                    }
                }
            }
            .opacity(isHovered || isRestarting ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Delete Service Button

struct DeleteServiceButton: View {
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                Text("Delete")
                    .font(.system(size: 11))
            }
            .foregroundStyle(isHovered ? .red : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.red.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Redeploy Button

struct RedeployButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                }
                Text(isLoading ? "Deploying..." : "Redeploy")
                    .font(.system(size: 11))
            }
            .foregroundStyle(isHovered ? .primary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    let mockService = Service(id: "1", name: "web-app")
    let mockProject = Project(
        id: "1",
        name: "My Project",
        services: ServiceConnection(edges: [ServiceEdge(node: mockService)]),
        environments: EnvironmentConnection(edges: [
            EnvironmentEdge(node: RailwayEnvironment(id: "env1", name: "production"))
        ])
    )
    
    DeploymentsView(
        service: mockService,
        project: mockProject,
        environmentId: "env1",
        onDismiss: {},
        onDeleteService: { }
    )
    .environment(AppState())
    .frame(width: 320, height: 400)
}
