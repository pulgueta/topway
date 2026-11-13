import SwiftUI

/// The pages of the welcome window, in order.
enum WelcomePage: Int, CaseIterable, Identifiable {
    case welcome
    case health
    case actions
    case start

    var id: Self { self }

    /// The number that the page indicator gives, from 1.
    var number: Int { rawValue + 1 }

    var previous: WelcomePage? { WelcomePage(rawValue: rawValue - 1) }
    var next: WelcomePage? { WelcomePage(rawValue: rawValue + 1) }

    var heading: LocalizedStringKey {
        switch self {
        case .welcome: "Welcome to Topway"
        case .health: "See the health of your services"
        case .actions: "Work from the menu bar"
        case .start: "Find Topway in the menu bar"
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .welcome:
            "Topway shows your Railway projects in the menu bar. See their health and control your services without the Railway dashboard."
        case .health:
            "The Topway icon shows the health of all your services. Turn on alerts in Settings to get a notification when a deployment fails, a service crashes or a service recovers."
        case .actions:
            "Restart and redeploy services, edit variables and read live logs. Before a risky change, Topway asks you to confirm and tells you when the deployment is ready."
        case .start:
            "Click the Topway icon at the top right of the screen. Then select **Sign in with Railway** or **Try with sample data**."
        }
    }

    /// What VoiceOver reads for the picture on the stage.
    var pictureDescription: LocalizedStringKey {
        switch self {
        case .welcome:
            "Picture of the Topway projects list with sample projects and services."
        case .health:
            "Picture of the menu bar icon. It is a tram when all services are healthy, arrows when a build or a deploy is in progress, and a triangle when a service failed or crashed."
        case .actions:
            "Picture of the deployments of a sample service. Each deployment has View logs, Restart and Manage."
        case .start:
            "Picture of the menu bar with the selected Topway icon, and the Topway start screen below it."
        }
    }
}
