import Foundation
import TopwayCore

/// Describes one action that can need a confirmation from the user.
struct ConfirmationRequest: Identifiable {
    let id = UUID()
    let harm: HarmLevel
    let title: String
    let message: String
    let actionTitle: String
    var isDestructive = false
    /// The text that the user must type when `harm` is `.high`.
    var targetName = ""
    /// The environment that the action changes. A production environment shows a red label.
    var environmentName: String?
    let perform: () async -> Void
}
