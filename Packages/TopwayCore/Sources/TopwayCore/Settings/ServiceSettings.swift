import Foundation

/// The settings of a service that Topway shows and changes. The name is the same in all
/// environments. The other settings belong to one environment. An empty text means that
/// the setting is not set, and Railway then uses its default.
public struct ServiceSettings: Hashable, Sendable {
    public var name: String
    /// The repository or the image of the service. Topway does not change it.
    public let source: String?
    private var values: [ServiceSetting: String]

    public init(name: String, source: String? = nil, values: [ServiceSetting: String] = [:]) {
        self.name = name
        self.source = source
        self.values = values.filter { !$0.value.isEmpty }
    }

    /// An empty text removes the value, so two settings with no value are equal.
    public subscript(setting: ServiceSetting) -> String {
        get { values[setting] ?? "" }
        set { values[setting] = newValue.isEmpty ? nil : newValue }
    }

    /// The first problem of the values, or `nil`. A save uses `problem(comparedTo:)`.
    public var problem: ServiceSettingsProblem? {
        if Self.clean(name).isEmpty { return .emptyName }
        let path = Self.clean(self[.healthcheckPath])
        return path.isEmpty || path.hasPrefix("/") ? nil : .healthcheckPath
    }

    /// The first problem that stops a save of the changes from `original`. A healthcheck
    /// path that the user did not change is not a problem: Railway has it, and it must
    /// not stop a save of the other settings.
    public func problem(comparedTo original: ServiceSettings) -> ServiceSettingsProblem? {
        switch problem {
        case .healthcheckPath where changes(from: original).instance[.healthcheckPath] == nil:
            nil
        case let problem:
            problem
        }
    }

    /// The settings that are different from `original`. Spaces around a value are not a
    /// difference.
    public func changes(from original: ServiceSettings) -> ServiceSettingsChanges {
        let newName = Self.clean(name)
        var instance: [ServiceSetting: String] = [:]
        for setting in ServiceSetting.allCases {
            let value = Self.clean(self[setting])
            if value != Self.clean(original[setting]) {
                instance[setting] = value
            }
        }
        return ServiceSettingsChanges(
            name: newName == Self.clean(original.name) ? nil : newName, instance: instance)
    }

    private static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
