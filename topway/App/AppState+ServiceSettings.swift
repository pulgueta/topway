import TopwayCore

extension AppState {
    /// Returns `nil` when the fetch fails or is cancelled.
    func fetchServiceSettings(environmentId: String, serviceId: String) async -> ServiceSettings? {
        await run {
            try await $0.fetchServiceSettings(
                environmentId: environmentId, serviceId: serviceId, token: $1)
        }
    }

    /// A new name changes the projects list, so the projects load again.
    func updateServiceSettings(
        _ changes: ServiceSettingsChanges, environmentId: String, serviceId: String
    ) async -> Bool {
        let didSave = await runAction(failure: "Railway did not save the settings. Try again.") {
            try await $0.updateServiceSettings(
                changes, environmentId: environmentId, serviceId: serviceId, token: $1)
        }
        if didSave, changes.name != nil {
            await loadProjects()
        }
        return didSave
    }
}
