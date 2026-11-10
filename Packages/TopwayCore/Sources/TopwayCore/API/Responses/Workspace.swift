struct Workspace: Decodable {
    let projects: ProjectConnection

    var projectList: [Project] {
        projects.edges.map { $0.node }
    }
}
