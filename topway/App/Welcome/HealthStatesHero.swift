import SwiftUI

/// The picture of the health page: the three menu bar icons and what each one means.
struct HealthStatesHero: View {
    /// The symbols of `MenuBarLabel`, one for each `Health`. `HealthSummary` cannot make a
    /// failing or in-progress value outside `TopwayCore`, so the symbols are here again.
    /// When you change a symbol in `MenuBarLabel`, change it here too.
    private let states: [(symbol: String, title: LocalizedStringKey)] = [
        ("tram.fill", "Healthy"),
        ("arrow.triangle.2.circlepath", "In progress"),
        ("exclamationmark.triangle.fill", "Failed"),
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            ForEach(states, id: \.symbol) { state in
                VStack(spacing: 10) {
                    Image(systemName: state.symbol)
                        .font(.system(size: 26, weight: .medium))
                        .frame(width: 92, height: 64)
                        .background { WelcomeSurface(cornerRadius: 16) }
                    Text(state.title)
                        .font(.headline)
                }
                .frame(minWidth: 92)
            }
        }
        // The page text tells what the icon does. VoiceOver also reads what each icon means.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "The menu bar icon is a tram when all services are healthy, arrows when a build or a deploy is in progress, and a triangle when a service failed or crashed."
        )
    }
}
