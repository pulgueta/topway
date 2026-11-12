import Foundation

public enum EnvironmentRules {
    /// The name that Topway sends to Railway: the typed name with no spaces around it.
    public static func cleanName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Gives the problem of a name for a new environment, or `nil` when the name is permitted.
    /// Two names that are different only in letter case are the same name.
    public static func problem(name: String, existingNames: [String]) -> EnvironmentNameProblem? {
        let clean = cleanName(name).lowercased()
        if clean.isEmpty { return .empty }
        return existingNames.contains { $0.lowercased() == clean } ? .duplicate : nil
    }

    /// The harm of a new environment. An empty environment costs nothing, so it needs no
    /// dialog. A copy of an environment starts its services, and Railway bills their usage.
    public static func createHarm(hasSource: Bool) -> HarmLevel {
        hasSource ? .medium : .low
    }
}
