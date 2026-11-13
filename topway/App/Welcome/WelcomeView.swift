import SwiftUI

/// The welcome window. It shows one time, at the first launch. Its pages tell what Topway
/// does and where the menu bar icon is. Topway has no Dock icon, so without this window
/// the user can see nothing.
///
/// The style is the style of the App Store screenshots: the text on the leading side, and
/// on the trailing side a stage with a copy of a part of Topway.
struct WelcomeView: View {
    /// The `UserDefaults` key that records that the welcome window showed.
    static let shownKey = "welcomeWindowShown"

    @AppStorage(WelcomeView.shownKey) private var isShown = false
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: WelcomePage
    /// The data of the copies of the app, when it is ready before the window shows (the
    /// previews).
    @Environment(\.welcomeSample) private var readySample
    /// The data of the copies of the app that the window reads. `nil` until it is read.
    @State private var loadedSample: WelcomeSample?
    /// The pages get the keyboard focus, so the arrow keys work also when Full Keyboard
    /// Access is off.
    @FocusState private var isPagesFocused: Bool

    /// - Parameter page: The page that shows first. The app uses the first page. The
    ///   previews use it to show each page.
    init(page: WelcomePage = .welcome) {
        _page = State(initialValue: page)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                pages

                WelcomeNavigationBar(page: page, goBack: goBack, goForward: goForward, close: close)
                    .animation(.screenChange, value: page)
            }
            .frame(width: WelcomeLayout.textWidth)
            .padding(.top, WelcomeLayout.textTop)
            .padding(.bottom, WelcomeLayout.margin)
            .frame(width: WelcomeLayout.stageLeading)

            stage
        }
        // The size is fixed. The window has no title bar, so the ground fills it to the
        // top edge.
        .frame(width: WelcomeLayout.contentWidth, height: WelcomeLayout.contentHeight)
        .background(WelcomePalette.ground)
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
        .task {
            // The sample data is in memory, so it is ready almost at once.
            guard readySample == nil else { return }
            loadedSample = await WelcomeSample.load()
        }
    }

    /// All texts are in the stack, so the bottom bar stays at the same position. Only the
    /// current page is visible and available to VoiceOver.
    private var pages: some View {
        ZStack(alignment: .topLeading) {
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

    /// The stage goes to the trailing and bottom edges of the window, and cuts the copy of
    /// the app there. The copy is in an overlay, so its true size does not change the size
    /// of the stage. Only the copy of the current page is in the stage. It fades when the
    /// page changes.
    private var stage: some View {
        WelcomeStageShape(cut: WelcomeLayout.stageCut)
            .fill(WelcomePalette.stage)
            .overlay(alignment: .topLeading) {
                if let sample = readySample ?? loadedSample {
                    WelcomeFragment(page: page, sample: sample)
                        .id(page)
                        .transition(.opacity)
                        .padding(.leading, WelcomeLayout.stageInset)
                        .padding(.top, WelcomeLayout.stageInset)
                }
            }
            .clipShape(WelcomeStageShape(cut: WelcomeLayout.stageCut))
            .animation(.screenChange, value: page)
            .padding(.top, WelcomeLayout.stageTop)
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

#Preview("1 Welcome", traits: .modifier(WelcomeSamplePreview())) {
    WelcomeView()
}

#Preview("2 Health", traits: .modifier(WelcomeSamplePreview())) {
    WelcomeView(page: .health)
}

#Preview("3 Actions", traits: .modifier(WelcomeSamplePreview())) {
    WelcomeView(page: .actions)
}

#Preview("4 Start", traits: .modifier(WelcomeSamplePreview())) {
    WelcomeView(page: .start)
}
