import SwiftUI

enum VariablesViewDestination: Equatable {
    case list
    case edit(EnvironmentVariable?)
    case deployments
    
    static func == (lhs: VariablesViewDestination, rhs: VariablesViewDestination) -> Bool {
        switch (lhs, rhs) {
        case (.list, .list), (.deployments, .deployments):
            return true
        case let (.edit(lhsVar), .edit(rhsVar)):
            return lhsVar?.id == rhsVar?.id
        default:
            return false
        }
    }
}

struct VariablesView: View {
    @Environment(AppState.self) private var appState
    
    let service: Service
    let project: Project
    let onDismiss: () -> Void
    
    @State private var variables: [EnvironmentVariable] = []
    @State private var isLoading = true
    @State private var selectedEnvironmentId: String?
    @State private var copiedVariable: String?
    @State private var currentDestination: VariablesViewDestination = .list
    
    private var environments: [RailwayEnvironment] {
        project.environmentList
    }
    
    var body: some View {
        ZStack {
            switch currentDestination {
            case .list:
                variablesListView
                    .transition(.opacity)
            case .edit(let variable):
                EditVariableView(
                    projectId: project.id,
                    environmentId: selectedEnvironmentId ?? "",
                    serviceId: service.id,
                    existingVariable: variable,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentDestination = .list
                        }
                    },
                    onSave: {
                        Task { await loadVariables() }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .deployments:
                DeploymentsView(
                    service: service,
                    project: project,
                    environmentId: selectedEnvironmentId ?? "",
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentDestination = .list
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onChange(of: selectedEnvironmentId) { _, newValue in
            if newValue != nil {
                Task { await loadVariables() }
            }
        }
        .task {
            if selectedEnvironmentId == nil, let firstEnv = environments.first {
                selectedEnvironmentId = firstEnv.id
            }
            await loadVariables()
        }
    }
    
    // MARK: - Variables List View
    
    private var variablesListView: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Service Info
            serviceInfoView
            
            Divider()
            
            // Environment Picker (if multiple environments)
            if environments.count > 1 {
                environmentPickerView
                Divider()
            }
            
            // Content
            contentView
            
            Divider()
            
            // Footer
            footerView
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            BackButton { onDismiss() }
            
            Spacer()
            
            Text("Variables")
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            // Add variable button
            IconButton(icon: "plus", help: "Add variable") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentDestination = .edit(nil)
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
    
    // MARK: - Environment Picker
    
    private var environmentPickerView: some View {
        HStack {
            Text("Environment")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Picker("", selection: $selectedEnvironmentId) {
                ForEach(environments) { env in
                    Text(env.name).tag(Optional(env.id))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: 140)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            VStack(spacing: 12) {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                Text("Loading variables...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if variables.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "key")
                    .font(.system(size: 32))
                    .foregroundStyle(.tertiary)
                Text("No Variables")
                    .font(.system(size: 14, weight: .semibold))
                Text("This service has no environment variables.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(variables) { variable in
                        VariableRow(
                            variable: variable,
                            isCopied: copiedVariable == variable.name,
                            onCopy: {
                                copyToClipboard(variable)
                            },
                            onEdit: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentDestination = .edit(variable)
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
        HStack {
            Text("\(variables.count) variable\(variables.count == 1 ? "" : "s")")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            
            Spacer()
            
            // Deployments button
            DeploymentsButton {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentDestination = .deployments
                }
            }
            
            if !variables.isEmpty {
                CopyAllButton { copyAllToClipboard() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions
    
    private func loadVariables() async {
        guard let envId = selectedEnvironmentId else { return }
        
        isLoading = true
        variables = await appState.fetchVariables(
            projectId: project.id,
            environmentId: envId,
            serviceId: service.id
        )
        isLoading = false
    }
    
    private func copyToClipboard(_ variable: EnvironmentVariable) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(variable.value, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            copiedVariable = variable.name
        }
        
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.2)) {
                if copiedVariable == variable.name {
                    copiedVariable = nil
                }
            }
        }
    }
    
    private func copyAllToClipboard() {
        let content = variables
            .map { "\($0.name)=\($0.value)" }
            .joined(separator: "\n")
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
}

// MARK: - Back Button

struct BackButton: View {
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Copy All Button

struct CopyAllButton: View {
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isCopied = false
    
    var body: some View {
        Button {
            action()
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = true
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCopied = false
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10))
                Text(isCopied ? "Copied!" : "Copy All")
                    .font(.system(size: 11))
            }
            .foregroundStyle(isCopied ? .green : (isHovered ? .primary : .secondary))
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

// MARK: - Variable Row

struct VariableRow: View {
    let variable: EnvironmentVariable
    let isCopied: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    
    @State private var isHovered = false
    @State private var isValueVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Variable Name + Actions
            HStack {
                Text(variable.name)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    // Edit Button
                    IconButton(
                        icon: "pencil",
                        help: "Edit variable"
                    ) {
                        onEdit()
                    }
                    
                    // Toggle Visibility
                    IconButton(
                        icon: isValueVisible ? "eye.slash" : "eye",
                        help: isValueVisible ? "Hide value" : "Show value"
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isValueVisible.toggle()
                        }
                    }
                    
                    // Copy Button
                    IconButton(
                        icon: isCopied ? "checkmark" : "doc.on.doc",
                        tint: isCopied ? .green : nil,
                        help: "Copy value"
                    ) {
                        onCopy()
                    }
                }
                .opacity(isHovered || isCopied ? 1 : 0)
            }
            
            // Variable Value
            Group {
                if isValueVisible {
                    Text(variable.value)
                        .textSelection(.enabled)
                } else {
                    Text(String(repeating: "•", count: min(variable.value.count, 24)))
                }
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
            .lineLimit(2)
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

// MARK: - Deployments Button

struct DeploymentsButton: View {
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10))
                Text("Deploys")
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

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    var tint: Color? = nil
    let help: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(tint ?? (isHovered ? Color.primary : Color.secondary))
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
                )
                .contentShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .help(help)
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
    
    VariablesView(service: mockService, project: mockProject, onDismiss: {})
        .environment(AppState())
        .frame(width: 320, height: 400)
}
