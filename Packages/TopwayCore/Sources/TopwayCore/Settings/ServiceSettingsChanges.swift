/// The settings that the user changed. Topway sends only these to Railway.
public struct ServiceSettingsChanges: Hashable, Sendable {
    /// The new name of the service, in all environments. `nil` when the name did not change.
    public let name: String?
    /// The new values in one environment. An empty value removes the setting.
    public let instance: [ServiceSetting: String]

    public init(name: String? = nil, instance: [ServiceSetting: String] = [:]) {
        self.name = name
        self.instance = instance
    }

    public var isEmpty: Bool {
        name == nil && instance.isEmpty
    }
}
