import SwiftUI

/// The picture on the stage of a page: a copy of a part of Topway, made with the views of
/// the app and the sample data. It is a picture, not a control: the pointer, the keyboard and
/// VoiceOver cannot use the controls in it, and VoiceOver reads one short description.
struct WelcomeFragment: View {
    let page: WelcomePage
    let sample: WelcomeSample

    var body: some View {
        content
            // The copies are dark in all appearances, as in the App Store screenshots.
            .environment(\.colorScheme, .dark)
            .allowsHitTesting(false)
            // Tab does not stop on the controls in the copy when keyboard navigation is on.
            // `.disabled(true)` also does this, but it dims the buttons.
            .focusable(false)
            // `.ignore`, not `.combine`: a combined element gets the actions of the buttons
            // in the copy, and VoiceOver then offers them.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(page.pictureDescription)
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .welcome: ProjectsFragment(projects: sample.projects)
        case .health: HealthFragment(states: sample.healthStates)
        case .actions: DeploymentsFragment(sample: sample)
        case .start: StartFragment()
        }
    }
}
