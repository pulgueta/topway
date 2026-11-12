import Foundation

extension RailwayClient {
    private static let workflowPollInterval = Duration.seconds(2)
    /// 30 polls of 2 seconds: Topway waits 60 seconds for the workflow.
    private static let workflowPolls = 30
    /// The wait also stops at this time, because slow requests make 30 polls longer.
    private static let workflowWaitSeconds: TimeInterval = 60
    /// One status request must not use the full wait.
    private static let workflowRequestTimeout: TimeInterval = 10

    /// Sends two requests. The template is public, so its request has no
    /// token, as in the Railway CLI. The deploy request sends the configuration of the
    /// template back to Railway. Railway then makes the service in a workflow.
    public func deployDatabase(
        _ template: DatabaseTemplate, projectId: String, environmentId: String, token: String
    ) async throws -> String? {
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
        return deploy.templateDeployV2.workflowId
    }

    /// Asks for the status each 2 seconds, for at most 60 seconds. Railway accepted the
    /// deploy before this wait, so a status request that fails does not mean that the
    /// deploy failed: it gives `pending`. Only the status `Error` throws.
    public func waitForDatabase(workflowId: String, token: String) async throws
        -> DatabaseDeployResult
    {
        let query = """
            query WorkflowStatus($workflowId: String!) {
              workflowStatus(workflowId: $workflowId) {
                status
                error
              }
            }
            """
        let deadline = now().addingTimeInterval(Self.workflowWaitSeconds)
        for _ in 0..<Self.workflowPolls {
            do {
                try await sleep(Self.workflowPollInterval)
            } catch {
                // Only a cancelled sleep throws.
                throw RailwayError.cancelled
            }
            guard now() < deadline else { break }

            let step: WorkflowStep
            do {
                let data: WorkflowStatusData = try await execute(
                    query: query, json: ["workflowId": .string(workflowId)], token: token,
                    timeout: Self.workflowRequestTimeout)
                step = data.workflowStatus.step
            } catch RailwayError.cancelled {
                throw RailwayError.cancelled
            } catch {
                return .pending
            }

            switch step {
            case .done: return .complete
            case .failed(let message): throw RailwayError.graphQLError(message)
            case .wait: continue
            }
        }
        return .pending
    }
}
