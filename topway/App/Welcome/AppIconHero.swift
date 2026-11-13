import SwiftUI

/// The picture of the first page: the app icon on a soft light.
struct AppIconHero: View {
    var body: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: WelcomeLayout.appIconSize, height: WelcomeLayout.appIconSize)
            .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
            .background {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.35), .clear], center: .center,
                            startRadius: 0, endRadius: WelcomeLayout.appIconSize)
                    )
                    .frame(
                        width: WelcomeLayout.appIconSize * 2, height: WelcomeLayout.appIconSize * 2)
            }
            .accessibilityHidden(true)
    }
}
