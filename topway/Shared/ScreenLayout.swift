import SwiftUI

/// The layout of every screen: a top bar, the content, and a bottom bar.
///
/// The bars are the control layer. `safeAreaBar` keeps the content clear of the bars and
/// gives a scroll view the system scroll edge effect, so content that scrolls under a bar
/// stays readable. To change how all bars sit on the content, change only this view.
struct ScreenLayout<Top: View, Content: View, Bottom: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var top: Top
    @ViewBuilder var bottom: Bottom

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The soft edge lets rows show through a bar on macOS. The hard edge keeps the
            // text of a bar clear of the rows that scroll under it.
            .scrollEdgeEffectStyle(.hard, for: [.top, .bottom])
            .safeAreaBar(edge: .top, spacing: 0) {
                VStack(spacing: 0) { top }
            }
            .safeAreaBar(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) { bottom }
            }
    }
}
