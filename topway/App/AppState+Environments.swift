import TopwayCore

/// The environment actions. Each one loads the projects again when Railway accepts it, so
/// the environment lists show the change.
extension AppState {
    func createEnvironment(projectId: String, name: String, sourceEnvironmentId: String?) async
        -> Bool
    {
        let id = await run { source, token in
            try await source.createEnvironment(
                projectId: projectId, name: name, sourceEnvironmentId: sourceEnvironmentId,
                token: token)
        }
        guard id != nil else { return false }
        await loadProjects()
        return true
    }

    func deleteEnvironment(environmentId: String) async -> Bool {
        let didDelete = await runAction(
            failure: "Railway did not delete the environment. Try again."
        ) { source, token in
            try await source.deleteEnvironment(environmentId: environmentId, token: token)
        }
        if didDelete {
            await loadProjects()
        }
        return didDelete
    }
}
