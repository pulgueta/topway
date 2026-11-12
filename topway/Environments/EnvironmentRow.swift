import SwiftUI
import TopwayCore

/// One environment of a project, with its delete action.
struct EnvironmentRow: View {
    let environment: RailwayEnvironment
    let onRequestDelete: () -> Void

    var body: some View {
        HStack(spacing: Layout.controlSpacing) {
            Image(systemName: "square.stack.3d.up")
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .accessibilityHidden(true)

            Text(environment.name)
                .fontWeight(.medium)
                .lineLimit(1)

            Spacer(minLength: Layout.controlSpacing)

            Button("Delete…", role: .destructive) { onRequestDelete() }
                .buttonStyle(.bordered)
                .controlSize(.small)
                // The role alone does not color a bordered button on macOS.
                .foregroundStyle(.red)
                .help("Delete \(environment.name) from this project.")
                // Each row has this button, so the label names the environment.
                .accessibilityLabel("Delete \(environment.name)")
                .accessibilityInputLabels(["Delete", "Delete \(environment.name)"])
        }
        .padding(.horizontal, Layout.contentInset)
        .padding(.vertical, Layout.controlSpacing)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, Layout.contentInset)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(environment.name)
    }
}
