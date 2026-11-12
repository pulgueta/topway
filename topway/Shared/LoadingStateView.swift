import SwiftUI

/// Fills the content area while the first load of a screen runs.
struct LoadingStateView: View {
    /// Says what loads, for example "Loading projects…".
    let title: String

    var body: some View {
        ProgressView(title)
            .controlSize(.small)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
