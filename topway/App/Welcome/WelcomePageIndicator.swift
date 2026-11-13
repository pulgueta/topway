import SwiftUI

/// One dot for each page. The dot of the current page is wider and has the ink color.
struct WelcomePageIndicator: View {
    let page: WelcomePage

    var body: some View {
        HStack(spacing: WelcomeLayout.dotSize) {
            ForEach(WelcomePage.allCases) { item in
                Capsule()
                    .fill(item == page ? WelcomePalette.ink : WelcomePalette.dot)
                    .frame(
                        width: item == page ? WelcomeLayout.currentDotWidth : WelcomeLayout.dotSize,
                        height: WelcomeLayout.dotSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page.number) of \(WelcomePage.allCases.count)")
    }
}
