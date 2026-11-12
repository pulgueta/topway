import Foundation

public enum DomainRules {
    /// The name that Topway sends to Railway: lowercase, with no spaces around it, no
    /// scheme, no path and no dot at the end. A user can paste a URL.
    public static func cleanName(_ text: String) -> String {
        var name = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for scheme in ["https://", "http://"] where name.hasPrefix(scheme) {
            name.removeFirst(scheme.count)
        }
        name = String(name.prefix { $0 != "/" && $0 != "?" })
        if name.hasSuffix(".") {
            name.removeLast()
        }
        return name
    }

    /// Gives the problem of a name for a custom domain, or `nil` when the name is permitted.
    /// A permitted name has 2 or more labels and at most 253 characters. A label has 1 to 63
    /// characters (a to z, 0 to 9 and the hyphen) and no hyphen at its start or end. The
    /// last label is not only digits. The first label can be `*`, for a wildcard domain.
    public static func problem(name: String, existingNames: [String]) -> DomainNameProblem? {
        let clean = cleanName(name)
        if clean.isEmpty { return .empty }
        if clean == "railway.app" || clean.hasSuffix(".railway.app") { return .railwayDomain }

        var labels = clean.split(separator: ".", omittingEmptySubsequences: false)
        if labels.first == "*" {
            labels.removeFirst()
        }
        guard clean.count <= 253, labels.count >= 2, labels.allSatisfy(isLabel),
            labels.last?.allSatisfy(\.isNumber) == false
        else { return .invalid }

        return existingNames.contains { cleanName($0) == clean } ? .duplicate : nil
    }

    /// Railway gives a service one domain of its own in an environment.
    public static func canAddRailwayDomain(to domains: [Domain]) -> Bool {
        !domains.contains { $0.kind == .railway }
    }

    private static func isLabel(_ label: Substring) -> Bool {
        (1...63).contains(label.count) && !label.hasPrefix("-") && !label.hasSuffix("-")
            && label.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
    }
}
