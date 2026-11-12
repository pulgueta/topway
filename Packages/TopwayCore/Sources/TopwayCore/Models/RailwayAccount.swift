/// The signed-in Railway user, from the `me` query. Railway gives the name and the email
/// only with the `profile` and `email` scopes.
public struct RailwayAccount: Decodable, Sendable, Equatable {
    public let name: String?
    public let email: String
    /// Only the workspaces that the user selected on the consent page.
    public let workspaces: [WorkspaceSummary]

    public init(name: String?, email: String, workspaces: [WorkspaceSummary]) {
        self.name = name
        self.email = email
        self.workspaces = workspaces
    }
}
