import SwiftUI
import TopwayCore

/// The Metrics tab of the service screen: one chart for each metric, and the time range.
struct MetricsView: View {
    @Environment(AppState.self) private var appState

    let service: Service
    let environmentId: String

    /// `nil` before the first load and after a load that failed.
    @State private var metrics: ServiceMetrics?
    @State private var window = MetricWindow.hour
    @State private var isLoading = true
    @State private var latestLoadID = UUID()

    var body: some View {
        ScreenLayout {
            content
        } top: {
            EmptyView()
        } bottom: {
            // With charts on the screen, the error belongs to a reload, not to the first load.
            if let error = appState.errorMessage, metrics != nil {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        // Runs at the start and for each new time range.
        .task(id: window) {
            await loadMetrics()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let metrics, !metrics.isEmpty {
            // The charts stay while a reload runs, so the screen does not flash.
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(metrics.series) { series in
                        MetricCard(series: series)
                    }
                }
            }
        } else if isLoading {
            LoadingStateView(title: "Loading metrics…")
        } else if metrics == nil {
            // The error can be gone, for example after a new token, but the metrics did not load.
            ErrorStateView(
                title: "Metrics did not load",
                message: appState.errorMessage ?? "Select Try again to load the metrics."
            ) {
                Task { await loadMetrics() }
            }
        } else {
            ContentUnavailableView(
                "No metrics",
                systemImage: "chart.xyaxis.line",
                description: Text(
                    "Railway has no metrics for this service in this time range. Select a longer time range, or deploy the service."
                )
            )
        }
    }

    // MARK: - Footer

    private var footer: some View {
        ActionBar {
            if isLoading && metrics != nil {
                Text("Loading metrics…")
            }
        } actions: {
            Picker("Time range", selection: $window) {
                ForEach(MetricWindow.allCases) { window in
                    Text(window.title).tag(window)
                }
            }
            // The selected value is the visible text. The label stays for VoiceOver.
            .labelsHidden()
            .fixedSize()
            .help("Select the time range of the charts.")

            Button("Refresh", systemImage: "arrow.clockwise") {
                Task { await loadMetrics() }
            }
            .buttonStyle(.glass)
            .disabled(isLoading)
            .help("Load the metrics of \(service.name) again.")
        }
    }

    // MARK: - Actions

    private func loadMetrics() async {
        let loadID = UUID()
        latestLoadID = loadID
        isLoading = true
        let fetched = await appState.fetchMetrics(
            environmentId: environmentId, serviceId: service.id, window: window)
        // Only the latest call may update the screen.
        guard loadID == latestLoadID else { return }
        metrics = fetched
        isLoading = false
    }
}

#Preview {
    MetricsView(service: Service(id: "1", name: "web-app"), environmentId: "env1")
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
