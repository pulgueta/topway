import SwiftUI

/// Reads the sample data before a preview of the welcome window renders, so the preview
/// shows the copies of the app.
struct WelcomeSamplePreview: PreviewModifier {
    static func makeSharedContext() async -> WelcomeSample {
        await WelcomeSample.load()
    }

    func body(content: Content, context: WelcomeSample) -> some View {
        content.environment(\.welcomeSample, context)
    }
}
