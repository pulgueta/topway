import SwiftUI

/// One page of the welcome window: a picture, a heading, a message and, on the last page,
/// the notes about a hidden icon and about privacy.
struct WelcomePageView: View {
    let page: WelcomePage
    /// `true` when the page shows. The heading then gets the VoiceOver focus.
    let isCurrent: Bool

    @AccessibilityFocusState private var isHeadingFocused: Bool

    var body: some View {
        VStack(spacing: WelcomeLayout.textSpacing) {
            hero
                .frame(height: WelcomeLayout.heroHeight)
                .padding(.bottom, WelcomeLayout.heroSpacing - WelcomeLayout.textSpacing)

            Text(page.heading)
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isHeadingFocused)

            Text(page.message)
                .font(.title3)

            if page == .start {
                startNotes
                    .padding(.top, WelcomeLayout.textSpacing)
            }
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: WelcomeLayout.textWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // The page shows after a press of Continue or Back. VoiceOver then reads the new
        // heading first.
        .task(id: isCurrent) {
            guard isCurrent else { return }
            isHeadingFocused = true
        }
    }

    @ViewBuilder
    private var hero: some View {
        switch page {
        case .welcome: AppIconHero()
        case .health: HealthStatesHero()
        case .actions: ActionsHero()
        case .start: MenuBarHero()
        }
    }

    private var startNotes: some View {
        VStack(spacing: WelcomeLayout.textSpacing) {
            Label {
                Text(
                    "If you cannot see the icon, the menu bar can be full. Quit some menu bar apps to make space, or turn on Topway in System Settings > Menu Bar."
                )
            } icon: {
                Image(systemName: "menubar.rectangle")
            }
            .font(.callout)
            .multilineTextAlignment(.leading)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { WelcomeSurface(cornerRadius: 12) }

            Label("Topway collects no data.", systemImage: "hand.raised.fill")
                .font(.callout)
                .fontWeight(.medium)
        }
    }
}
