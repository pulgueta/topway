import Foundation

enum RailwayError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case graphQLError(String)
    case unauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .graphQLError(let message):
            return "API error: \(message)"
        case .unauthorized:
            return "Invalid API token"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

@MainActor
final class RailwayClient {
    private let baseURL = "https://backboard.railway.com/graphql/v2"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Fetch Projects

    func fetchProjects(workspaceId: String, token: String) async throws -> [Project] {
        let query = """
        query Projects($workspaceId: String!) {
          workspace(workspaceId: $workspaceId) {
            projects {
              edges {
                node {
                  id
                  name
                  deletedAt
                  services {
                    edges {
                      node {
                        id
                        name
                      }
                    }
                  }
                  environments {
                    edges {
                      node {
                        id
                        name
                      }
                    }
                  }
                }
              }
            }
          }
        }
        """

        let response: GraphQLResponse<WorkspaceData> = try await executeQuery(
            query: query,
            variables: ["workspaceId": workspaceId],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        guard let data = response.data else {
            throw RailwayError.unknown
        }

        return data.workspace.projectList
    }

    // MARK: - Create Service with GitHub Repo

    func createService(projectId: String, repo: String, token: String) async throws -> String {
        let mutation = """
        mutation ServiceCreate($projectId: String!, $repo: String!) {
          serviceCreate(input: { projectId: $projectId, source: { repo: $repo } }) {
            id
          }
        }
        """

        let response: GraphQLResponse<ServiceCreateData> = try await executeQuery(
            query: mutation,
            variables: ["projectId": projectId, "repo": repo],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        guard let data = response.data else {
            throw RailwayError.unknown
        }

        return data.serviceCreate.id
    }

    // MARK: - Create Service with Docker Image

    func createServiceWithImage(projectId: String, image: String, token: String) async throws -> String {
        let mutation = """
        mutation ServiceCreate($projectId: String!, $image: String!) {
          serviceCreate(input: { projectId: $projectId, source: { image: $image } }) {
            id
          }
        }
        """

        let response: GraphQLResponse<ServiceCreateData> = try await executeQuery(
            query: mutation,
            variables: ["projectId": projectId, "image": image],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        guard let data = response.data else {
            throw RailwayError.unknown
        }

        return data.serviceCreate.id
    }

    // MARK: - Fetch Variables for a Service

    func fetchVariables(projectId: String, environmentId: String, serviceId: String, token: String) async throws -> [String: String] {
        let query = """
        query Variables($projectId: String!, $environmentId: String!, $serviceId: String!) {
          variables(
            projectId: $projectId
            environmentId: $environmentId
            serviceId: $serviceId
          )
        }
        """

        let response: GraphQLResponse<VariablesData> = try await executeQuery(
            query: query,
            variables: [
                "projectId": projectId,
                "environmentId": environmentId,
                "serviceId": serviceId,
            ],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        guard let data = response.data else {
            throw RailwayError.unknown
        }

        return data.variables
    }

    // MARK: - Delete Project

    func deleteProject(projectId: String, token: String) async throws -> Bool {
        let mutation = """
        mutation ProjectDelete($id: String!) {
          projectDelete(id: $id)
        }
        """

        let response: GraphQLResponse<ProjectDeleteData> = try await executeQuery(
            query: mutation,
            variables: ["id": projectId],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        guard let data = response.data else {
            throw RailwayError.unknown
        }

        return data.projectDelete
    }

    // MARK: - Upsert Variable

    func upsertVariable(projectId: String, environmentId: String, serviceId: String, name: String, value: String, token: String) async throws -> Bool {
        let mutation = """
        mutation VariableUpsert($projectId: String!, $environmentId: String!, $serviceId: String!, $name: String!, $value: String!) {
          variableUpsert(
            input: {
              projectId: $projectId
              environmentId: $environmentId
              serviceId: $serviceId
              name: $name
              value: $value
            }
          )
        }
        """

        let response: GraphQLResponse<VariableUpsertData> = try await executeQuery(
            query: mutation,
            variables: [
                "projectId": projectId,
                "environmentId": environmentId,
                "serviceId": serviceId,
                "name": name,
                "value": value,
            ],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        return response.data?.variableUpsert ?? false
    }

    // MARK: - Delete Variable

    func deleteVariable(projectId: String, environmentId: String, serviceId: String, name: String, token: String) async throws -> Bool {
        let mutation = """
        mutation VariableDelete($projectId: String!, $environmentId: String!, $serviceId: String!, $name: String!) {
          variableDelete(
            input: {
              projectId: $projectId
              environmentId: $environmentId
              serviceId: $serviceId
              name: $name
            }
          )
        }
        """

        let response: GraphQLResponse<VariableDeleteData> = try await executeQuery(
            query: mutation,
            variables: [
                "projectId": projectId,
                "environmentId": environmentId,
                "serviceId": serviceId,
                "name": name,
            ],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        return response.data?.variableDelete ?? false
    }

    // MARK: - Delete Service

    func deleteService(serviceId: String, token: String) async throws -> Bool {
        let mutation = """
        mutation ServiceDelete($id: String!) {
          serviceDelete(id: $id)
        }
        """

        let response: GraphQLResponse<ServiceDeleteData> = try await executeQuery(
            query: mutation,
            variables: ["id": serviceId],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        return response.data?.serviceDelete ?? false
    }

    // MARK: - Fetch Deployments

    func fetchDeployments(projectId: String, environmentId: String, serviceId: String, token: String) async throws -> [Deployment] {
        let query = """
        query Deployments($projectId: String!, $environmentId: String!, $serviceId: String!) {
          deployments(
            first: 10
            input: {
              projectId: $projectId
              environmentId: $environmentId
              serviceId: $serviceId
            }
          ) {
            edges {
              node {
                id
                status
                staticUrl
                createdAt
              }
            }
          }
        }
        """

        let response: GraphQLResponse<DeploymentsData> = try await executeQuery(
            query: query,
            variables: [
                "projectId": projectId,
                "environmentId": environmentId,
                "serviceId": serviceId,
            ],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        guard let data = response.data else {
            throw RailwayError.unknown
        }

        return data.deployments.edges.map { $0.node }
    }

    // MARK: - Restart Deployment

    func restartDeployment(deploymentId: String, token: String) async throws -> Bool {
        let mutation = """
        mutation DeploymentRestart($id: String!) {
          deploymentRestart(id: $id)
        }
        """

        let response: GraphQLResponse<DeploymentRestartData> = try await executeQuery(
            query: mutation,
            variables: ["id": deploymentId],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        return response.data?.deploymentRestart ?? false
    }

    // MARK: - Redeploy Service (trigger new deployment)

    func redeployService(environmentId: String, serviceId: String, token: String) async throws -> Bool {
        let mutation = """
        mutation ServiceInstanceRedeploy($environmentId: String!, $serviceId: String!) {
          serviceInstanceRedeploy(
            environmentId: $environmentId
            serviceId: $serviceId
          )
        }
        """

        let response: GraphQLResponse<ServiceRedeployData> = try await executeQuery(
            query: mutation,
            variables: ["environmentId": environmentId, "serviceId": serviceId],
            token: token
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        return response.data?.serviceInstanceRedeploy ?? false
    }

    // MARK: - Private Methods

    /// Executes a GraphQL operation. User-supplied values are passed as GraphQL
    /// `variables` (JSON-encoded by the transport), never interpolated into the
    /// query text — this eliminates GraphQL injection and quoting/escaping bugs.
    private func executeQuery<T: Decodable>(
        query: String,
        variables: [String: String] = [:],
        token: String
    ) async throws -> GraphQLResponse<T> {
        guard let url = URL(string: baseURL) else {
            throw RailwayError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = ["query": query]
        if !variables.isEmpty {
            body["variables"] = variables
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    throw RailwayError.unauthorized
                }
            }

            let decoder = JSONDecoder()
            return try decoder.decode(GraphQLResponse<T>.self, from: data)
        } catch let error as RailwayError {
            throw error
        } catch let error as DecodingError {
            throw RailwayError.decodingError(error)
        } catch {
            throw RailwayError.networkError(error)
        }
    }
}
