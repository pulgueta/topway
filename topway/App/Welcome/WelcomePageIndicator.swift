import SwiftUI

/// One dot for each page. The dot of the current page is wider and fully white.
struct WelcomePageIndicator: View {
    let page: WelcomePage

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(spacing: WelcomeLayout.dotSize) {
            ForEach(WelcomePage.allCases) { item in
                Capsule()
                    .fill(.white.opacity(item == page ? 1 : inactiveOpacity))
                    .frame(
                        width: item == page ? WelcomeLayout.currentDotWidth : WelcomeLayout.dotSize,
                        height: WelcomeLayout.dotSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page.number) of \(WelcomePage.allCases.count)")
    }

    /// The dot of another page has a contrast of at least 3:1 on the gradient.
    private var inactiveOpacity: Double {
        contrast == .increased ? 0.8 : 0.5
    }
}
