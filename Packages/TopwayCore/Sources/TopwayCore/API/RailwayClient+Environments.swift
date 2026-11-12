extension RailwayClient {
    public func createEnvironment(
        projectId: String, name: String, sourceEnvironmentId: String?, token: String
    ) async throws -> String {
        let mutation = """
            mutation EnvironmentCreate(
              $projectId: String!
              $name: String!
              $sourceEnvironmentId: String
            ) {
              environmentCreate(
                input: {
                  projectId: $projectId
                  name: $name
                  sourceEnvironmentId: $sourceEnvironmentId
                }
              ) {
                id
              }
            }
            """

        // With no source, the request has no `sourceEnvironmentId`, and Railway makes an
        // empty environment.
        var variables = ["projectId": projectId, "name": name]
        variables["sourceEnvironmentId"] = sourceEnvironmentId
        let data: EnvironmentCreateData = try await execute(
            query: mutation, variables: variables, token: token)
        return data.environmentCreate.id
    }

    public func deleteEnvironment(environmentId: String, token: String) async throws -> Bool {
        let mutation = """
            mutation EnvironmentDelete($id: String!) {
              environmentDelete(id: $id)
            }
            """

        let data: EnvironmentDeleteData = try await execute(
            query: mutation, variables: ["id": environmentId], token: token)
        return data.environmentDelete
    }
}
