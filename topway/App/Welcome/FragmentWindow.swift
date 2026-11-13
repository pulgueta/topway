import SwiftUI

/// A copy of the menu bar window: the dark fill, the round corners and the thin light edge
/// of a dark window. The content has the true size of the window (`Layout`), so the stage
/// cuts its bottom.
struct FragmentWindow<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: WelcomeLayout.appWindowRadius, style: .continuous)
        content
            .frame(width: Layout.windowWidth, height: Layout.windowHeight, alignment: .top)
            .background(WelcomePalette.appWindow, in: shape)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(WelcomePalette.appEdge)
            }
    }
}
