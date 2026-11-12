extension RailwayClient {
    /// Sends one request with one `variables` field for the shared variables and one for
    /// each service. The aliases `s0`, `s1`… and their variable names come from the position
    /// of the service, so the document has no user input. The service IDs go in variables.
    public func fetchProjectVariables(
        projectId: String, environmentId: String, serviceIds: [String], token: String
    ) async throws -> ProjectVariables {
        let arguments = serviceIds.indices.map { ", $s\($0): String!" }.joined()
        let fields = serviceIds.indices.map {
            """

              s\($0): variables(
                projectId: $projectId
                environmentId: $environmentId
                serviceId: $s\($0)
                unrendered: true
              )
            """
        }.joined()
        let query = """
            query ProjectVariables($projectId: String!, $environmentId: String!\(arguments)) {
              shared: variables(projectId: $projectId, environmentId: $environmentId, unrendered: true)\(fields)
            }
            """

        var variables = ["projectId": projectId, "environmentId": environmentId]
        for (index, serviceId) in serviceIds.enumerated() {
            variables["s\(index)"] = serviceId
        }

        // A sealed variable has the value `null`. Its name stays, with no value.
        let data: [String: [String: String?]] = try await execute(
            query: query, variables: variables, token: token)
        func values(_ alias: String) -> [String: String] {
            (data[alias] ?? [:]).mapValues { $0 ?? "" }
        }
        return ProjectVariables(
            shared: values("shared"),
            byService: Dictionary(
                serviceIds.enumerated().map { ($0.element, values("s\($0.offset)")) },
                uniquingKeysWith: { first, _ in first }))
    }
}
