/// The sample reads for references.
extension SampleDataSource {
    public func fetchProjectVariables(
        projectId: String, environmentId: String, serviceIds: [String], token: String
    ) -> ProjectVariables {
        ProjectVariables(
            shared: sharedVariables[environmentId] ?? [:],
            byService: Dictionary(
                serviceIds.map {
                    // A sealed variable is a target with no value, as in `RailwayClient`.
                    ($0, (variables[Self.key(environmentId, $0)] ?? [:]).mapValues { $0 ?? "" })
                },
                uniquingKeysWith: { first, _ in first }))
    }
}
