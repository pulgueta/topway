import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    
    let onDismiss: () -> Void
    
    @State private var token: String = ""
    @State private var workspace: String = ""
    @State private var autoRefreshEnabled: Bool = false
    @State private var refreshIntervalIndex: Int = 1 // Default 30 seconds
    
    private let refreshIntervals: [(label: String, seconds: TimeInterval)] = [
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                BackButton { onDismiss() }
                
                Spacer()
                
                Text("Settings")
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
                    // Token Field
                    FormField(
                        label: "API Token",
                        placeholder: "Enter your Railway API token",
                        text: $token,
                        isSecure: true
                    )
                    
                    // Workspace ID Field
                    FormField(
                        label: "Workspace ID",
                        placeholder: "Enter your Workspace ID",
                        text: $workspace
                    )
                    
                    // Help Text
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("Find your Workspace ID by pressing Cmd+K in Railway and selecting 'Copy Active Workspace ID'")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.03))
                    )
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Auto Refresh Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Auto Refresh")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Text("Enable auto-refresh")
                                .font(.system(size: 13))
                            
                            Spacer()
                            
                            Toggle("", isOn: $autoRefreshEnabled)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .labelsHidden()
                        }
                        
                        if autoRefreshEnabled {
                            HStack {
                                Text("Refresh every")
                                    .font(.system(size: 13))
                                
                                Spacer()
                                
                                Picker("", selection: $refreshIntervalIndex) {
                                    ForEach(0..<refreshIntervals.count, id: \.self) { index in
                                        Text(refreshIntervals[index].label).tag(index)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
            }
            
            Divider()
            
            // Footer with Save Button
            VStack {
                Button {
                    saveSettings()
                } label: {
                    Text("Save")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(token.isEmpty || workspace.isEmpty)
            }
            .padding(16)
        }
        .onAppear {
            token = appState.railwayToken
            workspace = appState.workspaceId
            autoRefreshEnabled = appState.autoRefreshEnabled
            // Find the matching interval index
            if let index = refreshIntervals.firstIndex(where: { $0.seconds == appState.autoRefreshInterval }) {
                refreshIntervalIndex = index
            }
        }
    }
    
    private func saveSettings() {
        appState.railwayToken = token
        appState.workspaceId = workspace
        appState.autoRefreshInterval = refreshIntervals[refreshIntervalIndex].seconds
        appState.autoRefreshEnabled = autoRefreshEnabled
        onDismiss()
        
        Task {
            await appState.loadProjects()
        }
    }
}

// MARK: - Form Field

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
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
                    .stroke(isFocused ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: 1)
            )
            .focused($isFocused)
        }
    }
}

#Preview {
    SettingsView(onDismiss: {})
        .environment(AppState())
        .frame(width: 320, height: 400)
}
