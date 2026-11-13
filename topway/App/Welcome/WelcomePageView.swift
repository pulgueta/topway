import SwiftUI

/// The text of one page of the welcome window: a headline, a message and, on the last
/// page, the notes about a hidden icon and about privacy.
struct WelcomePageView: View {
    let page: WelcomePage
    /// `true` when the page shows. The headline then gets the VoiceOver focus.
    let isCurrent: Bool

    @AccessibilityFocusState private var isHeadingFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: WelcomeLayout.textSpacing) {
            Text(page.heading)
                .font(.system(size: WelcomeLayout.headlineSize, weight: .semibold))
                .tracking(WelcomeLayout.headlineTracking)
                .lineHeight(.multiple(factor: 1))
                .foregroundStyle(WelcomePalette.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isHeadingFocused)

            Text(page.message)
                .font(.title3)
                .foregroundStyle(WelcomePalette.text)

            if page == .start {
                startNotes
            }
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: WelcomeLayout.textWidth, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        // The page shows after a press of Continue or Back. VoiceOver then reads the new
        // headline first.
        .task(id: isCurrent) {
            guard isCurrent else { return }
            isHeadingFocused = true
        }
    }

    /// Plain text on the ground, not a card, as the message.
    private var startNotes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                "If you cannot see the icon, the menu bar can be full. Quit some menu bar apps to make space, or turn on Topway in System Settings > Menu Bar."
            )

            Text("Topway collects no data.")
                .fontWeight(.medium)
        }
        .font(.body)
        .foregroundStyle(WelcomePalette.text)
    }
}
