extension RailwayClient {
    public func fetchServiceSettings(environmentId: String, serviceId: String, token: String)
        async throws -> ServiceSettings
    {
        // The settings are constants of Topway, not user input.
        let fields = ServiceSetting.allCases.map(\.rawValue).joined(separator: "\n    ")
        let query = """
            query ServiceSettings($environmentId: String!, $serviceId: String!) {
              serviceInstance(environmentId: $environmentId, serviceId: $serviceId) {
                serviceName
                source {
                  image
                  repo
                }
                \(fields)
              }
            }
            """

        let data: ServiceSettingsData = try await execute(
            query: query,
            variables: ["environmentId": environmentId, "serviceId": serviceId],
            token: token
        )
        return data.serviceInstance.settings
    }

    /// Sends the name first, then the settings of the environment, each only when it
    /// changed. The two requests are not one transaction: when the second request fails,
    /// the new name stays.
    public func updateServiceSettings(
        _ changes: ServiceSettingsChanges, environmentId: String, serviceId: String, token: String
    ) async throws -> Bool {
        if let name = changes.name {
            let mutation = """
                mutation ServiceUpdate($id: String!, $name: String!) {
                  serviceUpdate(id: $id, input: { name: $name }) {
                    id
                  }
                }
                """
            let _: ServiceUpdateData = try await execute(
                query: mutation, variables: ["id": serviceId, "name": name], token: token)
        }

        guard !changes.instance.isEmpty else { return true }
        let mutation = """
            mutation ServiceInstanceUpdate(
              $serviceId: String!
              $environmentId: String!
              $input: ServiceInstanceUpdateInput!
            ) {
              serviceInstanceUpdate(
                serviceId: $serviceId
                environmentId: $environmentId
                input: $input
              )
            }
            """
        // A field that is not in the input stays as it is. `null` removes a setting.
        let input = Dictionary(
            uniqueKeysWithValues: changes.instance.map { setting, value in
                (setting.rawValue, value.isEmpty ? JSONValue.null : .string(value))
            })
        let data: ServiceInstanceUpdateData = try await execute(
            query: mutation,
            json: [
                "serviceId": .string(serviceId), "environmentId": .string(environmentId),
                "input": .object(input),
            ],
            token: token
        )
        return data.serviceInstanceUpdate
    }
}
