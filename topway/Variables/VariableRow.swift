import SwiftUI
import TopwayCore

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
        .contentShape(.rect)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
