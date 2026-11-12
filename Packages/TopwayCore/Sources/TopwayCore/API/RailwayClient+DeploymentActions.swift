extension RailwayClient {
    public func rollbackDeployment(deploymentId: String, token: String) async throws -> Bool {
        try await deploymentAction("deploymentRollback", deploymentId: deploymentId, token: token)
    }

    public func cancelDeployment(deploymentId: String, token: String) async throws -> Bool {
        try await deploymentAction("deploymentCancel", deploymentId: deploymentId, token: token)
    }

    public func removeDeployment(deploymentId: String, token: String) async throws -> Bool {
        try await deploymentAction("deploymentRemove", deploymentId: deploymentId, token: token)
    }

    /// The three mutations have the same argument and give a Boolean.
    /// - Parameter field: A mutation name of Topway, not user input.
    private func deploymentAction(_ field: String, deploymentId: String, token: String)
        async throws -> Bool
    {
        let mutation = """
            mutation DeploymentAction($id: String!) {
              \(field)(id: $id)
            }
            """

        let data: [String: Bool] = try await execute(
            query: mutation, variables: ["id": deploymentId], token: token)
        guard let result = data[field] else { throw RailwayError.unknown }
        return result
    }
}
