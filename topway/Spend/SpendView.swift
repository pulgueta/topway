import SwiftUI
import TopwayCore

/// The usage screen: the cost and the resource usage of the current billing period of
/// the workspace. Railway gives the cost. Topway calculates no price.
struct SpendView: View {
    @Environment(AppState.self) private var appState

    let onDismiss: () -> Void

    /// `nil` before the first load and after a load that failed.
    @State private var spend: Spend?
    @State private var isLoading = true
    @State private var latestLoadID = UUID()

    var body: some View {
        ScreenLayout {
            content
        } top: {
            ScreenHeader(title: "Usage", backTitle: "Projects", onBack: { onDismiss() })
        } bottom: {
            // With usage on the screen, the error belongs to a reload, not to the first load.
            if let error = appState.errorMessage, spend != nil {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        .task {
            await loadSpend()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let spend {
            // The values stay while a reload runs, so the screen does not flash.
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SpendSummary(spend: spend, now: .now)

                    ForEach(spend.usage) { total in
                        LabeledContent(total.kind.title, value: total.kind.formatted(total.value))
                            .padding(.horizontal, Layout.contentInset)
                            .padding(.vertical, Layout.controlSpacing)
                            .overlay(alignment: .bottom) {
                                Divider()
                                    .padding(.leading, Layout.contentInset)
                            }
                    }

                    Text(
                        "Railway gives this cost, and it can be some minutes old. It is not your invoice: your plan, credits and taxes can change the amount."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(Layout.contentInset)
                }
            }
        } else if isLoading {
            LoadingStateView(title: "Loading usage…")
        } else {
            // The error can be gone, for example after a new token, but the usage did not load.
            ErrorStateView(
                title: "Usage did not load",
                message: appState.errorMessage ?? "Select Try again to load the usage."
            ) {
                Task { await loadSpend() }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        ActionBar {
            if isLoading && spend != nil {
                Text("Loading usage…")
            }
        } actions: {
            Button("Refresh", systemImage: "arrow.clockwise") {
                Task { await loadSpend() }
            }
            .buttonStyle(.glass)
            .disabled(isLoading)
            .help("Load the usage again.")
        }
    }

    // MARK: - Actions

    private func loadSpend() async {
        let loadID = UUID()
        latestLoadID = loadID
        isLoading = true
        let fetched = await appState.fetchSpend()
        // Only the latest call may update the screen.
        guard loadID == latestLoadID else { return }
        spend = fetched
        isLoading = false
    }
}

#Preview {
    SpendView(onDismiss: {})
        .environment(AppState())
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
