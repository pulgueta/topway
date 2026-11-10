struct Workspace: Decodable {
    let projects: ProjectConnection

    /// Projects without those that Railway marked as deleted (`deletedAt` is set).
    var projectList: [Project] {
        projects.edges.map(\.node).filter { $0.deletedAt == nil }
    }
}
