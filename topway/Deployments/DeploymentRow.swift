import SwiftUI
import TopwayCore

@MainActor
struct DeploymentRow: View {
    let deployment: Deployment
    let isRestarting: Bool
    let onRestart: () -> Void
    let onOpenURL: () -> Void

    @State private var isHovered = false
    @FocusState private var focusedAction: RowAction?
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled

    private enum RowAction: Hashable {
        case openURL
        case restart
    }

    private var areActionsVisible: Bool {
        isHovered || isRestarting || focusedAction != nil || isVoiceOverEnabled
    }

    private var statusColor: Color {
        switch deployment.statusColor {
        case "green": .green
        case "yellow": .yellow
        case "red": .red
        case "purple": .purple
        default: .gray
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
                    .focused($focusedAction, equals: .openURL)
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
                    .focused($focusedAction, equals: .restart)
                }
            }
            .opacity(areActionsVisible ? 1 : 0)
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
