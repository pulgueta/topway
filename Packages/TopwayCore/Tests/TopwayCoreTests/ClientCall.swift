import Testing
import TopwayCore

/// One client method, with the input names it must send as GraphQL variables.
struct ClientCall: Sendable, CustomTestStringConvertible {
    let name: String
    let reply: String
    let variableNames: Set<String>
    let run: @Sendable (RailwayClient, String) async throws -> Void

    var testDescription: String { name }

    static let all: [ClientCall] = [
        ClientCall(
            name: "fetchProjects",
            reply: #"{"data":{"workspace":{"projects":{"edges":[]}}}}"#,
            variableNames: ["workspaceId"],
            run: { client, input in
                _ = try await client.fetchProjects(workspaceId: input, token: "token")
            }),
        ClientCall(
            name: "createService",
            reply: #"{"data":{"serviceCreate":{"id":"s1"}}}"#,
            variableNames: ["projectId", "repo"],
            run: { client, input in
                _ = try await client.createService(projectId: input, repo: input, token: "token")
            }),
        ClientCall(
            name: "createServiceWithImage",
            reply: #"{"data":{"serviceCreate":{"id":"s1"}}}"#,
            variableNames: ["projectId", "image"],
            run: { client, input in
                _ = try await client.createServiceWithImage(
                    projectId: input, image: input, token: "token")
            }),
        ClientCall(
            name: "fetchVariables",
            reply: #"{"data":{"variables":{}}}"#,
            variableNames: ["projectId", "environmentId", "serviceId"],
            run: { client, input in
                _ = try await client.fetchVariables(
                    projectId: input, environmentId: input, serviceId: input, token: "token")
            }),
        ClientCall(
            name: "deleteProject",
            reply: #"{"data":{"projectDelete":true}}"#,
            variableNames: ["id"],
            run: { client, input in
                _ = try await client.deleteProject(projectId: input, token: "token")
            }),
        ClientCall(
            name: "upsertVariable",
            reply: #"{"data":{"variableUpsert":true}}"#,
            variableNames: ["projectId", "environmentId", "serviceId", "name", "value"],
            run: { client, input in
                _ = try await client.upsertVariable(
                    projectId: input, environmentId: input, serviceId: input, name: input,
                    value: input, token: "token")
            }),
        ClientCall(
            name: "deleteVariable",
            reply: #"{"data":{"variableDelete":true}}"#,
            variableNames: ["projectId", "environmentId", "serviceId", "name"],
            run: { client, input in
                _ = try await client.deleteVariable(
                    projectId: input, environmentId: input, serviceId: input, name: input,
                    token: "token")
            }),
        ClientCall(
            name: "deleteService",
            reply: #"{"data":{"serviceDelete":true}}"#,
            variableNames: ["id"],
            run: { client, input in
                _ = try await client.deleteService(serviceId: input, token: "token")
            }),
        ClientCall(
            name: "fetchDeployments",
            reply: #"{"data":{"deployments":{"edges":[]}}}"#,
            variableNames: ["projectId", "environmentId", "serviceId"],
            run: { client, input in
                _ = try await client.fetchDeployments(
                    projectId: input, environmentId: input, serviceId: input, token: "token")
            }),
        ClientCall(
            name: "restartDeployment",
            reply: #"{"data":{"deploymentRestart":true}}"#,
            variableNames: ["id"],
            run: { client, input in
                _ = try await client.restartDeployment(deploymentId: input, token: "token")
            }),
        ClientCall(
            name: "redeployService",
            reply: #"{"data":{"serviceInstanceRedeploy":true}}"#,
            variableNames: ["environmentId", "serviceId"],
            run: { client, input in
                _ = try await client.redeployService(
                    environmentId: input, serviceId: input, token: "token")
            }),
        ClientCall(
            name: "createEnvironment",
            reply: #"{"data":{"environmentCreate":{"id":"e1"}}}"#,
            variableNames: ["projectId", "name", "sourceEnvironmentId"],
            run: { client, input in
                _ = try await client.createEnvironment(
                    projectId: input, name: input, sourceEnvironmentId: input, token: "token")
            }),
        ClientCall(
            name: "deleteEnvironment",
            reply: #"{"data":{"environmentDelete":true}}"#,
            variableNames: ["id"],
            run: { client, input in
                _ = try await client.deleteEnvironment(environmentId: input, token: "token")
            }),
        ClientCall(
            name: "rollbackDeployment",
            reply: #"{"data":{"deploymentRollback":true}}"#,
            variableNames: ["id"],
            run: { client, input in
                _ = try await client.rollbackDeployment(deploymentId: input, token: "token")
            }),
        ClientCall(
            name: "cancelDeployment",
            reply: #"{"data":{"deploymentCancel":true}}"#,
            variableNames: ["id"],
            run: { client, input in
                _ = try await client.cancelDeployment(deploymentId: input, token: "token")
            }),
        ClientCall(
            name: "removeDeployment",
            reply: #"{"data":{"deploymentRemove":true}}"#,
            variableNames: ["id"],
            run: { client, input in
                _ = try await client.removeDeployment(deploymentId: input, token: "token")
            }),
    ]
}
