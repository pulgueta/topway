import SwiftUI

enum ServiceSourceType: String, CaseIterable {
    case gitHub = "GitHub"
    case docker = "Docker"
}

struct AddServiceView: View {
    @Environment(AppState.self) private var appState
    
    let projectId: String
    let projectName: String
    let onDismiss: () -> Void
    
    @State private var sourceType: ServiceSourceType = .gitHub
    @State private var repoName: String = ""
    @State private var imageName: String = ""
    @State private var isCreating = false
    
    private var sourceValue: String {
        sourceType == .gitHub ? repoName : imageName
    }
    
    private var isInputValid: Bool {
        !sourceValue.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                BackButton { onDismiss() }
                
                Spacer()
                
                Text("Add Service")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Project Info
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                        Text(projectName)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.03))
                    )
                    
                    // Source Type Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source Type")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 8) {
                            SourceTypeButton(
                                label: "GitHub",
                                icon: "link",
                                isSelected: sourceType == .gitHub
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    sourceType = .gitHub
                                }
                            }
                            
                            SourceTypeButton(
                                label: "Docker",
                                icon: "shippingbox.fill",
                                isSelected: sourceType == .docker
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    sourceType = .docker
                                }
                            }
                        }
                    }
                    
                    // Input Field based on source type
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sourceType == .gitHub ? "GitHub Repository" : "Docker Image")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        TextField(
                            sourceType == .gitHub ? "owner/repository" : "image:tag",
                            text: sourceType == .gitHub ? $repoName : $imageName
                        )
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        
                        Text(sourceType == .gitHub
                             ? "e.g., railwayapp-templates/django"
                             : "e.g., nginx:latest")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    
                    // Error Message
                    if let error = appState.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                            Text(error)
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
                .padding(16)
            }
            
            Divider()
            
            // Footer with Create Button
            VStack {
                Button {
                    createService()
                } label: {
                    if isCreating {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Service")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isInputValid || isCreating)
            }
            .padding(16)
        }
    }
    
    private func createService() {
        isCreating = true
        appState.clearError()
        
        Task {
            let success: Bool
            if sourceType == .gitHub {
                success = await appState.createService(
                    projectId: projectId,
                    repo: repoName.trimmingCharacters(in: .whitespaces)
                )
            } else {
                success = await appState.createServiceWithImage(
                    projectId: projectId,
                    image: imageName.trimmingCharacters(in: .whitespaces)
                )
            }
            
            isCreating = false
            
            if success {
                onDismiss()
            }
        }
    }
}

// MARK: - Source Type Button

struct SourceTypeButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    AddServiceView(projectId: "123", projectName: "My Project", onDismiss: {})
        .environment(AppState())
        .frame(width: 320, height: 400)
}
