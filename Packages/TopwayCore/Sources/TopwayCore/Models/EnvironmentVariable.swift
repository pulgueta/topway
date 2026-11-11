public struct EnvironmentVariable: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.id = name
        self.name = name
        self.value = value
    }
}
