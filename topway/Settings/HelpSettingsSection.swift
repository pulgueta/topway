import SwiftUI
import TopwayCore

/// The Help setting. Each button opens an issue form on GitHub with the Mac details filled in.
struct HelpSettingsSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            LabeledContent("Topway did something wrong") {
                Button("Report a problem") { openReport(.bug) }
                    .help("Open the bug report form on GitHub in your browser.")
            }
            LabeledContent("Topway quit unexpectedly") {
                Button("Report a crash") { openReport(.crash) }
                    .help("Open the crash report form on GitHub in your browser.")
            }
        } header: {
            Text("Help")
        } footer: {
            Text(
                "Topway opens GitHub in your browser and fills in the details of your Mac. Topway sends nothing by itself. You send the report."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private func openReport(_ kind: IssueKind) {
        let details = DeviceDetails.current(isSampleMode: appState.isSampleMode)
        if let url = IssueReportLink.url(for: kind, details: details) {
            openURL(url)
        }
    }
}
