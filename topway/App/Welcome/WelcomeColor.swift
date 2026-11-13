import SwiftUI

/// A color of the welcome window. It changes with the appearance (light or dark) and with
/// Increase Contrast. `WelcomePalette` has the values.
nonisolated struct WelcomeColor: ShapeStyle {
    let light: Color
    let dark: Color
    /// The colors with Increase Contrast. `nil` keeps the normal color.
    var increasedContrastLight: Color?
    var increasedContrastDark: Color?

    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        let isIncreased = environment.colorSchemeContrast == .increased
        let color =
            if environment.colorScheme == .dark {
                isIncreased ? increasedContrastDark ?? dark : dark
            } else {
                isIncreased ? increasedContrastLight ?? light : light
            }
        return color.resolve(in: environment)
    }
}
