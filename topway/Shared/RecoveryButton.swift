import SwiftUI
import TopwayCore

/// One action on the error screen. The first action of the screen is the primary button.
struct RecoveryButton: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings

    let action: RecoveryAction
    let isPrimary: Bool
    let onRetry: () -> Void

    var body: some View {
        if isPrimary {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var button: some View {
        switch action {
        case .retry:
            Button("Try again") { onRetry() }
        case .openSettings:
            Button("Open Settings") { openAppSettings(fallback: openSettings) }
        case .useSampleData:
            Button("Try with sample data") { appState.enterSampleMode() }
                .help("Show sample projects. Topway does not connect to Railway.")
        }
    }
}
