extension RailwayClient {
    private static let workflowPollInterval = Duration.seconds(2)
    /// 30 polls of 2 seconds: Topway waits 60 seconds for the workflow.
    private static let workflowPolls = 30

    /// Sends two requests, then polls. The template is public, so its request has no
    /// token, as in the Railway CLI. The deploy request sends the configuration of the
    /// template back to Railway. Railway then makes the service in a workflow.
    public func deployDatabase(
        _ template: DatabaseTemplate, projectId: String, environmentId: String, token: String
    ) async throws -> Bool {
        let templateQuery = """
            query TemplateDetail($code: String!) {
              template(code: $code) {
                id
                serializedConfig
              }
            }
            """
        let detail: TemplateData = try await execute(
            query: templateQuery, variables: ["code": template.rawValue], token: nil)
        guard let config = detail.template.serializedConfig, config != .null else {
            throw TemplateConfigProblem.noConfiguration
        }

        let mutation = """
            mutation TemplateDeploy(
              $projectId: String!
              $environmentId: String!
              $templateId: String!
              $serializedConfig: SerializedTemplateConfig!
            ) {
              templateDeployV2(
                input: {
                  projectId: $projectId
                  environmentId: $environmentId
                  templateId: $templateId
                  serializedConfig: $serializedConfig
                }
              ) {
                workflowId
              }
            }
            """
        let deploy: TemplateDeployData = try await execute(
            query: mutation,
            json: [
                "projectId": .string(projectId), "environmentId": .string(environmentId),
                "templateId": .string(detail.template.id),
                "serializedConfig": try TemplateConfig.filled(config),
            ],
            token: token
        )
        guard let workflowId = deploy.templateDeployV2.workflowId else { return true }
        return try await waitForWorkflow(workflowId, token: token)
    }

    /// Returns `false` when the workflow still runs after the wait time.
    private func waitForWorkflow(_ workflowId: String, token: String) async throws -> Bool {
        let query = """
            query WorkflowStatus($workflowId: String!) {
              workflowStatus(workflowId: $workflowId) {
                status
                error
              }
            }
            """
        for _ in 0..<Self.workflowPolls {
            try await sleep(Self.workflowPollInterval)
            let data: WorkflowStatusData = try await execute(
                query: query, variables: ["workflowId": workflowId], token: token)
            switch data.workflowStatus.step {
            case .done: return true
            case .failed(let message): throw RailwayError.graphQLError(message)
            case .wait: continue
            }
        }
        return false
    }
}
