import TopwayCore

extension AppState {
    /// Adds a database to a project, then loads the projects again. Returns `true` when
    /// Railway accepted the request. When Railway did not finish in the wait time, a
    /// message says that the database can show later.
    func deployDatabase(_ template: DatabaseTemplate, projectId: String, environmentId: String)
        async -> Bool
    {
        let isComplete = await run {
            try await $0.deployDatabase(
                template, projectId: projectId, environmentId: environmentId, token: $1)
        }
        guard let isComplete else { return false }
        await loadProjects()
        if !isComplete {
            errorMessage =
                "Railway did not add \(template.title) in 60 seconds. Select Refresh later to see it."
        }
        return true
    }
}
