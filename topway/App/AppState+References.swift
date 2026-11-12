import TopwayCore

extension AppState {
    /// Returns `nil` when the fetch fails or is cancelled.
    func fetchProjectVariables(projectId: String, environmentId: String, serviceIds: [String])
        async -> ProjectVariables?
    {
        await run {
            try await $0.fetchProjectVariables(
                projectId: projectId, environmentId: environmentId, serviceIds: serviceIds,
                token: $1)
        }
    }
}
