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
    @State private var streamState: LogStreamState = .connecting
    @State private var attempt = 0
    @State private var isFollowing = true
    @State private var position = ScrollPosition(edge: .bottom)

    init(service: Service, deployment: Deployment, onDismiss: @escaping () -> Void) {
        self.service = service
        self.deployment = deployment
        self.onDismiss = onDismiss
        _kind = State(initialValue: deployment.defaultLogKind)
    }

    /// A new value starts a new stream.
    private struct StreamID: Equatable {
        let kind: LogKind
        let attempt: Int
    }

    var body: some View {
        ScreenLayout {
            contentView
        } top: {
            ScreenHeader(title: "Logs", backTitle: "Deployments", onBack: { onDismiss() })
            infoView
        } bottom: {
            if let error = appState.errorMessage, !buffer.entries.isEmpty {
                ErrorBanner(
                    message: error, onDismiss: { appState.clearError() },
                    onRetry: { attempt += 1 })
            }
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

    // MARK: - Deployment Info

    private var infoView: some View {
        HStack(spacing: Layout.controlSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("\(deployment.statusDisplay) · \(deployment.formattedDate)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: Layout.controlSpacing)

            Picker("Log type", selection: $kind) {
                Text("Build").tag(LogKind.build)
                Text("Deploy").tag(LogKind.deploy)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .help("Show the build log or the deploy log.")
        }
        .padding(.horizontal, Layout.barPadding)
        .padding(.bottom, Layout.controlSpacing)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if !buffer.entries.isEmpty {
            linesView
        } else if case .connecting = streamState {
            LoadingStateView(title: "Loading logs…")
        } else if let error = appState.errorMessage {
            ErrorStateView(title: "Logs did not load", message: error) { attempt += 1 }
        } else {
            ContentUnavailableView(
                "No logs", systemImage: "text.alignleft", description: Text(emptyMessage))
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
        // Dense log text under the bars makes the controls hard to read, so the edge is hard.
        .scrollEdgeEffectStyle(.hard, for: .vertical)
        .scrollPosition($position)
        .onScrollGeometryChange(for: LogScrollMetrics.self) { geometry in
            // The bottom bar covers the bottom inset, so that part does not show lines.
            LogScrollMetrics(
                offsetY: geometry.contentOffset.y, contentHeight: geometry.contentSize.height,
                visibleMaxY: geometry.visibleRect.maxY - geometry.contentInsets.bottom)
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
                .buttonStyle(.glass)
                .controlSize(.small)
                .help("Go to the newest line and show new lines when they arrive.")
                .padding(Layout.controlSpacing)
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        ActionBar {
            LogConnectionLabel(state: streamState)
        } actions: {
            if !buffer.entries.isEmpty {
                CopyButton(title: "Copy logs") { copyLogs() }
                    .buttonStyle(.glass)
                    .help("Copy the lines on this screen, with their timestamps.")
            }
        }
    }

    // MARK: - Actions

    private func copyLogs() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(buffer.text, forType: .string)
    }
}
