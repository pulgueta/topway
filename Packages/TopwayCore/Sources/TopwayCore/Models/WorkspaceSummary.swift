/// A workspace that the user shared with Topway on the consent page of Railway.
public struct WorkspaceSummary: Decodable, Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
