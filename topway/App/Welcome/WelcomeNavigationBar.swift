import SwiftUI

/// The bottom bar of the welcome window: **Skip**, the page indicator, **Back**, and
/// **Continue** or **Done**.
struct WelcomeNavigationBar: View {
    let page: WelcomePage
    let goBack: () -> Void
    let goForward: () -> Void
    let close: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: Layout.controlSpacing) {
            HStack(spacing: Layout.controlSpacing) {
                HStack {
                    if page.next != nil {
                        Button("Skip", action: close)
                            .keyboardShortcut(.cancelAction)
                            .help("Close the welcome window.")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                WelcomePageIndicator(page: page)

                HStack(spacing: Layout.controlSpacing) {
                    if page.previous != nil {
                        Button("Back", action: goBack)
                            .help("Go to the previous page.")
                    }

                    Button(page.next == nil ? "Done" : "Continue", action: goForward)
                        .buttonStyle(.glassProminent)
                        .tint(.white)
                        .keyboardShortcut(.defaultAction)
                        .help(
                            page.next == nil ? "Close the welcome window." : "Go to the next page.")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}
