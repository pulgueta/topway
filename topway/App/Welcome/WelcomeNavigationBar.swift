import SwiftUI

/// The bottom bar of the welcome window: the page indicator, then **Skip**, **Back**, and
/// **Continue** or **Done**. The page indicator has its own row, so it stays at the same
/// position on all pages.
struct WelcomeNavigationBar: View {
    let page: WelcomePage
    let goBack: () -> Void
    let goForward: () -> Void
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WelcomeLayout.textSpacing) {
            WelcomePageIndicator(page: page)

            GlassEffectContainer(spacing: Layout.controlSpacing) {
                HStack(spacing: Layout.controlSpacing) {
                    if page.next != nil {
                        Button("Skip", action: close)
                            .keyboardShortcut(.cancelAction)
                            .help("Close the welcome window.")
                    }

                    Spacer(minLength: 0)

                    if page.previous != nil {
                        Button("Back", action: goBack)
                            .help("Go to the previous page.")
                    }

                    // A dark button on the light ground, and a light button in the dark
                    // appearance. The system gives the label a color that contrasts.
                    Button(page.next == nil ? "Done" : "Continue", action: goForward)
                        .buttonStyle(.glassProminent)
                        .tint(WelcomePalette.ink)
                        .keyboardShortcut(.defaultAction)
                        .help(
                            page.next == nil ? "Close the welcome window." : "Go to the next page.")
                }
            }
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}
