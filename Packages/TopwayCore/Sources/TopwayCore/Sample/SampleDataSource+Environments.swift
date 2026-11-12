import Foundation

/// The sample actions on environments.
extension SampleDataSource {
    /// With a source, the new environment gets its variables, and each service of the
    /// source starts a deployment. Throws when the project does not exist or has the name.
    public func createEnvironment(
        projectId: String, name: String, sourceEnvironmentId: String?, token: String
    ) throws -> String {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else {
            throw RailwayError.graphQLError("Project not found.")
        }
        let project = projects[index]
        let names = project.environmentList.map(\.name)
        guard EnvironmentRules.problem(name: name, existingNames: names) == nil else {
            throw RailwayError.graphQLError("The project has an environment with this name.")
        }

        environmentCount += 1
        let environment = RailwayEnvironment(id: "environment-\(environmentCount)", name: name)
        replaceEnvironments(inProjectAt: index, with: project.environmentList + [environment])
        if let sourceEnvironmentId {
            sharedVariables[environment.id] = sharedVariables[sourceEnvironmentId]
            for service in project.serviceList {
                let source = Self.key(sourceEnvironmentId, service.id)
                let target = Self.key(environment.id, service.id)
                // Railway does not copy a sealed variable to a new environment.
                variables[target] = variables[source]?.filter { $0.value != nil }
                if deployments[source] != nil {
                    startDeployment(key: target)
                }
            }
        }
        return environment.id
    }

    /// Returns `false` when the environment does not exist.
    public func deleteEnvironment(environmentId: String, token: String) -> Bool {
        guard
            let index = projects.firstIndex(where: {
                $0.environmentList.contains { $0.id == environmentId }
            })
        else { return false }
        let project = projects[index]
        replaceEnvironments(
            inProjectAt: index, with: project.environmentList.filter { $0.id != environmentId })
        sharedVariables[environmentId] = nil
        for service in project.serviceList {
            deployments[Self.key(environmentId, service.id)] = nil
            variables[Self.key(environmentId, service.id)] = nil
        }
        return true
    }

    // MARK: - Private Methods

    private func replaceEnvironments(
        inProjectAt index: Int, with environments: [RailwayEnvironment]
    ) {
        let project = projects[index]
        projects[index] = Project(
            id: project.id, name: project.name, services: project.services,
            environments: EnvironmentConnection(
                edges: environments.map { EnvironmentEdge(node: $0) }))
    }
}
