import SwiftUI

extension EnvironmentValues {
    /// The data of the copies of the app in the welcome window, when it is ready before the
    /// window shows. The previews set it (`WelcomeSamplePreview`), because a static preview
    /// does not wait for `WelcomeSample.load()`. The app does not set it.
    @Entry var welcomeSample: WelcomeSample?
}
