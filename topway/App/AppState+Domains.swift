import TopwayCore

extension AppState {
    /// Returns `nil` when the fetch fails or is cancelled. An empty array means no domains.
    func fetchDomains(projectId: String, environmentId: String, serviceId: String) async
        -> [Domain]?
    {
        await run {
            try await $0.fetchDomains(
                projectId: projectId, environmentId: environmentId, serviceId: serviceId,
                token: $1)
        }
    }

    func addRailwayDomain(environmentId: String, serviceId: String) async -> Bool {
        await run {
            try await $0.createRailwayDomain(
                environmentId: environmentId, serviceId: serviceId, token: $1)
        } != nil
    }

    func addCustomDomain(
        projectId: String, environmentId: String, serviceId: String, name: String
    ) async -> Bool {
        await run {
            try await $0.createCustomDomain(
                projectId: projectId, environmentId: environmentId, serviceId: serviceId,
                name: name, token: $1)
        } != nil
    }

    func deleteDomain(_ domain: Domain) async -> Bool {
        await runAction(failure: "Railway did not delete the domain. Try again.") {
            try await $0.deleteDomain(id: domain.id, kind: domain.kind, token: $1)
        }
    }
}
