import SwiftUI
import TopwayCore

/// Shows the build log or the deploy log of one deployment while new lines arrive.
/// The stream stops when the screen closes or the tab changes.
struct LogsView: View {
    @Environment(AppState.self) private var appState

    let service: Service
    let deployment: Deployment
    let onDismiss: () -> Void

    @State private var kind: LogKind
    @State private var buffer = LogBuffer()
    @State private var streamState: StreamState = .connecting
    @State private var attempt = 0
    @State private var isFollowing = true
    @State private var position = ScrollPosition(edge: .bottom)

    init(service: Service, deployment: Deployment, onDismiss: @escaping () -> Void) {
        self.service = service
        self.deployment = deployment
        self.onDismiss = onDismiss
        _kind = State(initialValue: deployment.defaultLogKind)
    }

    private enum StreamState {
        case connecting
        case connection(LogConnection)
        /// The stream finished with no error.
        case ended
        /// An error stopped the stream. `ErrorBanner` or `ErrorStateView` shows it.
        case stopped
    }

    /// A new value starts a new stream.
    private struct StreamID: Equatable {
        let kind: LogKind
        let attempt: Int
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            infoView

            Divider()

            contentView

            if let error = appState.errorMessage, !buffer.entries.isEmpty {
                ErrorBanner(
                    message: error, onDismiss: { appState.clearError() },
                    onRetry: { attempt += 1 })
            }

            Divider()

            footerView
        }
        .task(id: StreamID(kind: kind, attempt: attempt)) {
            buffer = LogBuffer()
            streamState = .connecting
            isFollowing = true
            let isEnded = await appState.streamLogs(kind, deploymentId: deployment.id) { event in
                switch event {
                case .lines(let lines):
                    buffer.append(lines)
                case .connection(let connection):
                    streamState = .connection(connection)
                }
            }
            // A cancelled task belongs to a stream that a new stream replaced.
            if !Task.isCancelled {
                streamState = isEnded ? .ended : .stopped
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            BackButton { onDismiss() }

            Spacer()

            Text("Logs")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            // Keeps the title in the center.
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Deployment Info

    private var infoView: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text("\(deployment.statusDisplay) · \(deployment.formattedDate)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            Picker("Log type", selection: $kind) {
                Text("Build").tag(LogKind.build)
                Text("Deploy").tag(LogKind.deploy)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.small)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if !buffer.entries.isEmpty {
            linesView
        } else if case .connecting = streamState {
            VStack(spacing: 12) {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                Text("Loading logs...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = appState.errorMessage {
            ErrorStateView(message: error) { attempt += 1 }
        } else {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "text.alignleft")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)

                VStack(spacing: 4) {
                    Text("No Logs")
                        .font(.system(size: 14, weight: .semibold))

                    Text(emptyMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var emptyMessage: String {
        let log = kind == .build ? "build logs" : "deploy logs"
        if case .ended = streamState {
            return "This deployment has no \(log)."
        }
        return "This deployment has no \(log) yet. New lines show here."
    }

    private var linesView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(buffer.entries) { entry in
                    LogLineRow(line: entry.line)
                }
            }
            .padding(.vertical, 4)
        }
        .defaultScrollAnchor(.bottom)
        .scrollPosition($position)
        .onScrollGeometryChange(for: LogScrollMetrics.self) { geometry in
            LogScrollMetrics(
                offsetY: geometry.contentOffset.y, contentHeight: geometry.contentSize.height,
                visibleMaxY: geometry.visibleRect.maxY)
        } action: { old, new in
            isFollowing = new.isFollowing(after: old, wasFollowing: isFollowing)
        }
        .onChange(of: buffer.entries.last?.id) {
            if isFollowing {
                position.scrollTo(edge: .bottom)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !isFollowing {
                Button("Follow new lines", systemImage: "arrow.down.to.line") {
                    isFollowing = true
                    position.scrollTo(edge: .bottom)
                }
                .font(.system(size: 11))
                .buttonStyle(.glass)
                .controlSize(.small)
                .help("Go to the newest line and show new lines when they arrive")
                .padding(8)
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            connectionLabel

            Spacer()

            if !buffer.entries.isEmpty {
                CopyAllButton(title: "Copy logs") { copyLogs() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var connectionLabel: some View {
        let (text, symbol, color, help): (String, String, Color, String) =
            switch streamState {
            case .connecting:
                ("Connecting...", "ellipsis", .secondary, "Topway connects to Railway.")
            case .connection(.live):
                (
                    "Live", "dot.radiowaves.left.and.right", .green,
                    "New lines show when they arrive."
                )
            case .connection(.reconnecting):
                (
                    "Reconnecting...", "arrow.triangle.2.circlepath", .orange,
                    "The live connection stopped. Topway connects again."
                )
            case .connection(.polling):
                (
                    "Checks every 5 seconds", "clock.arrow.circlepath", .secondary,
                    "The live connection is not available. Topway reads the logs every 5 seconds."
                )
            case .ended:
                ("End of log", "checkmark.circle", .secondary, "This log has no more lines.")
            case .stopped:
                ("Stopped", "stop.circle", .secondary, "An error stopped this log.")
            }
        return Label {
            Text(text)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(color)
        }
        .font(.system(size: 11))
        .help(help)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Connection: \(text)")
    }

    // MARK: - Actions

    private func copyLogs() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(buffer.text, forType: .string)
    }
}
