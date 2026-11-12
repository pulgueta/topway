import SwiftUI
import TopwayCore

/// Tells the user that Railway reports an open incident. It shows on all screens, because
/// an incident can be the cause of a failed deployment or a failed request.
struct IncidentBanner: View {
    @Environment(\.openURL) private var openURL

    let incident: PlatformIncident
    let onHide: () -> Void
    /// Returns `true` only the first time for this incident.
    let shouldAnnounce: () -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: Layout.controlSpacing) {
                // The text keeps the primary color. Orange text on the orange tint is hard to read.
                Label {
                    Text("Railway incident")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .font(.callout.weight(.semibold))

                Spacer(minLength: Layout.controlSpacing)

                Button("Open status page") { openURL(incident.link) }
                    .help("Open the Railway status page in your browser.")

                Button("Hide") { onHide() }
                    .help("Hide this incident. A new incident shows again.")
                    .accessibilityLabel("Hide incident")
                    // Voice Control accepts the visible text.
                    .accessibilityInputLabels(["Hide", "Hide incident"])
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Text("\(incident.statusDisplay): \(incident.message)")
                .font(.callout)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Layout.barPadding)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Railway incident")
        // The banner shows with no user action, so VoiceOver must say it. The view shows
        // again each time the window opens, so only a new incident gets an announcement.
        .task(id: incident.id) {
            guard shouldAnnounce() else { return }
            AccessibilityNotification.Announcement(
                "Railway incident. \(incident.statusDisplay): \(incident.message)"
            ).post()
        }
    }
}

#Preview {
    IncidentBanner(
        incident: PlatformIncident(
            id: "1", message: "Builds are slow in all regions.", status: "INVESTIGATING",
            url: "https://status.railway.com"),
        onHide: {},
        shouldAnnounce: { true }
    )
    .frame(width: Layout.windowWidth)
}
