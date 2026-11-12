import SwiftUI

/// The layout of every screen: a top bar, the content, and a bottom bar.
///
/// The bars are the control layer. They sit above and below the content, not on it, so no
/// row can scroll under a bar and show through its text. The content fills the space between
/// the bars and is clipped to it. To change how all bars sit on the content, change only this
/// view.
struct ScreenLayout<Top: View, Content: View, Bottom: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var top: Top
    @ViewBuilder var bottom: Bottom

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) { top }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            VStack(spacing: 0) { bottom }
        }
    }
}
