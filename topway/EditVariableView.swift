import SwiftUI

struct EditVariableView: View {
    @Environment(AppState.self) private var appState
    
    let projectId: String
    let environmentId: String
    let serviceId: String
    let existingVariable: EnvironmentVariable?
    let onDismiss: () -> Void
    let onSave: () -> Void
    
    @State private var name: String = ""
    @State private var value: String = ""
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    
    private var isEditing: Bool {
        existingVariable != nil
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content - either form or delete confirmation
            if showDeleteConfirmation {
                deleteConfirmationView
            } else {
                formView
            }
            
            Divider()
            
            // Footer
            if !showDeleteConfirmation {
                footerView
            }
        }
        .onAppear {
            if let variable = existingVariable {
                name = variable.name
                value = variable.value
            }
        }
    }
    
    // MARK: - Form View
    
    private var formView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Name Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("VARIABLE_NAME", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .disabled(isEditing)
                        .opacity(isEditing ? 0.7 : 1)
                }
                
                // Value Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Value")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $value)
                        .font(.system(size: 13, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80, maxHeight: 120)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                }
                
                // Info Text
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text(isEditing ? "Editing will update this variable across all deployments." : "Variable names should be uppercase with underscores.")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }
    
    // MARK: - Delete Confirmation View
    
    private var deleteConfirmationView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            
            // Title
            Text("Delete Variable")
                .font(.system(size: 16, weight: .semibold))
            
            // Variable name
            Text("\"\(name)\"")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.secondary)
            
            // Warning message
            Text("This action cannot be undone.")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showDeleteConfirmation = false
                } label: {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.05))
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    Task { await deleteVariable() }
                } label: {
                    HStack(spacing: 6) {
                        if isDeleting {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.8)
                        }
                        Text("Delete")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            BackButton { onDismiss() }
            
            Spacer()
            
            Text(isEditing ? "Edit Variable" : "Add Variable")
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            // Delete button for existing variables
            if isEditing {
                IconButton(
                    icon: "trash",
                    tint: .red,
                    help: "Delete variable"
                ) {
                    showDeleteConfirmation = true
                }
            } else {
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Button("Cancel") {
                onDismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                Task { await saveVariable() }
            } label: {
                HStack(spacing: 6) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.8)
                    }
                    Text(isEditing ? "Update" : "Create")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(!isFormValid || isSaving)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Actions
    
    private func saveVariable() async {
        isSaving = true
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        let success = await appState.upsertVariable(
            projectId: projectId,
            environmentId: environmentId,
            serviceId: serviceId,
            name: trimmedName,
            value: value
        )
        
        isSaving = false
        
        if success {
            onSave()
            onDismiss()
        }
    }
    
    private func deleteVariable() async {
        isDeleting = true
        
        let success = await appState.deleteVariable(
            projectId: projectId,
            environmentId: environmentId,
            serviceId: serviceId,
            name: name
        )
        
        isDeleting = false
        
        if success {
            onSave()
            onDismiss()
        } else {
            // Show error, stay on confirmation view
            showDeleteConfirmation = false
        }
    }
}

#Preview {
    EditVariableView(
        projectId: "proj1",
        environmentId: "env1",
        serviceId: "svc1",
        existingVariable: nil,
        onDismiss: {},
        onSave: {}
    )
    .environment(AppState())
    .frame(width: 320, height: 400)
}
