import SwiftUI

/// The welcome window. It shows one time, at the first launch. Its pages tell what Topway
/// does and where the menu bar icon is. Topway has no Dock icon, so without this window
/// the user can see nothing.
struct WelcomeView: View {
    /// The `UserDefaults` key that records that the welcome window showed.
    static let shownKey = "welcomeWindowShown"

    @AppStorage(WelcomeView.shownKey) private var isShown = false
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: WelcomePage
    /// The pages get the keyboard focus, so the arrow keys work also when Full Keyboard
    /// Access is off.
    @FocusState private var isPagesFocused: Bool

    /// - Parameter page: The page that shows first. The app uses the first page. The
    ///   previews use it to show each page.
    init(page: WelcomePage = .welcome) {
        _page = State(initialValue: page)
    }

    var body: some View {
        VStack(spacing: WelcomeLayout.barSpacing) {
            pages

            WelcomeNavigationBar(page: page, goBack: goBack, goForward: goForward, close: close)
                .animation(.screenChange, value: page)
        }
        .padding(.horizontal, WelcomeLayout.sidePadding)
        .padding(.top, WelcomeLayout.topPadding)
        .padding(.bottom, WelcomeLayout.barSpacing)
        // The width is fixed. The height follows the tallest page and the text size.
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: WelcomeLayout.windowWidth)
        .background {
            // The window has no title bar, so the gradient fills it to the top edge.
            WelcomeBackground()
                .ignoresSafeArea()
        }
        // The gradient is dark enough for the dark appearance of the controls and of the
        // text in all system appearances.
        .environment(\.colorScheme, .dark)
        .defaultFocus($isPagesFocused, true)
        .onKeyPress(.leftArrow) {
            guard page.previous != nil else { return .ignored }
            goBack()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard page.next != nil else { return .ignored }
            goForward()
            return .handled
        }
        .onAppear {
            isShown = true
            // Topway is an accessory app, so the window can open behind other windows.
            NSApp.activate()
        }
    }

    /// All pages are in the stack, so the window keeps the height of the tallest page.
    /// Only the current page is visible and available to VoiceOver.
    private var pages: some View {
        ZStack(alignment: .top) {
            ForEach(WelcomePage.allCases) { item in
                WelcomePageView(page: item, isCurrent: item == page)
                    .opacity(item == page ? 1 : 0)
                    .offset(x: offset(of: item))
                    .accessibilityHidden(item != page)
            }
        }
        .animation(.screenChange, value: page)
        .focusable(interactions: .edit)
        .focusEffectDisabled()
        .focused($isPagesFocused)
    }

    /// An earlier page waits on the leading side, a later page on the trailing side. With
    /// Reduce Motion, the pages do not move. They only fade.
    private func offset(of item: WelcomePage) -> CGFloat {
        guard !reduceMotion, item != page else { return 0 }
        return item.rawValue < page.rawValue ? -WelcomeLayout.pageShift : WelcomeLayout.pageShift
    }

    private func goBack() {
        if let previous = page.previous {
            page = previous
        }
    }

    /// Goes to the next page. On the last page, closes the window.
    private func goForward() {
        if let next = page.next {
            page = next
        } else {
            close()
        }
    }

    private func close() {
        dismissWindow()
    }
}

#Preview("1 Welcome") {
    WelcomeView()
}

#Preview("2 Health") {
    WelcomeView(page: .health)
}

#Preview("3 Actions") {
    WelcomeView(page: .actions)
}

#Preview("4 Start") {
    WelcomeView(page: .start)
}
