import Foundation

public struct RailwayClient: Sendable {
    private let baseURL = "https://backboard.railway.com/graphql/v2"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Fetch Projects

    public func fetchProjects(workspaceId: String, token: String) async throws -> [Project] {
        let query = """
            query Projects($workspaceId: String!) {
              workspace(workspaceId: $workspaceId) {
                projects {
                  edges {
                    node {
                      id
                      name
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

        let data: WorkspaceData = try await execute(
            query: query,
            variables: ["workspaceId": workspaceId],
            token: token
        )
        return data.workspace.projectList
    }

    // MARK: - Create Service with GitHub Repo

    public func createService(projectId: String, repo: String, token: String) async throws -> String
    {
        let mutation = """
            mutation serviceCreate($projectId: String!, $repo: String!) {
              serviceCreate(input: { projectId: $projectId, source: { repo: $repo } }) {
                id
              }
            }
            """

        let data: ServiceCreateData = try await execute(
            query: mutation,
            variables: ["projectId": projectId, "repo": repo],
            token: token
        )
        return data.serviceCreate.id
    }

    // MARK: - Create Service with Docker Image

    public func createServiceWithImage(projectId: String, image: String, token: String) async throws
        -> String
    {
        let mutation = """
            mutation serviceCreate($projectId: String!, $image: String!) {
              serviceCreate(input: { projectId: $projectId, source: { image: $image } }) {
                id
              }
            }
            """

        let data: ServiceCreateData = try await execute(
            query: mutation,
            variables: ["projectId": projectId, "image": image],
            token: token
        )
        return data.serviceCreate.id
    }

    // MARK: - Fetch Variables for a Service

    public func fetchVariables(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) async throws -> [String: String] {
        let query = """
            query variables($projectId: String!, $environmentId: String!, $serviceId: String!) {
              variables(projectId: $projectId, environmentId: $environmentId, serviceId: $serviceId)
            }
            """

        let data: VariablesData = try await execute(
            query: query,
            variables: [
                "projectId": projectId,
                "environmentId": environmentId,
                "serviceId": serviceId,
            ],
            token: token
        )
        return data.variables
    }

    // MARK: - Delete Project

    public func deleteProject(projectId: String, token: String) async throws -> Bool {
        let mutation = """
            mutation projectDelete($id: String!) {
              projectDelete(id: $id)
            }
            """

        let data: ProjectDeleteData = try await execute(
            query: mutation,
            variables: ["id": projectId],
            token: token
        )
        return data.projectDelete
    }

    // MARK: - Upsert Variable

    public func upsertVariable(
        projectId: String, environmentId: String, serviceId: String, name: String, value: String,
        token: String
    ) async throws -> Bool {
        let mutation = """
            mutation variableUpsert(
              $projectId: String!
              $environmentId: String!
              $serviceId: String!
              $name: String!
              $value: String!
            ) {
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

        let data: VariableUpsertData = try await execute(
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
        return data.variableUpsert
    }

    // MARK: - Delete Variable

    public func deleteVariable(
        projectId: String, environmentId: String, serviceId: String, name: String, token: String
    ) async throws -> Bool {
        let mutation = """
            mutation variableDelete(
              $projectId: String!
              $environmentId: String!
              $serviceId: String!
              $name: String!
            ) {
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

        let data: VariableDeleteData = try await execute(
            query: mutation,
            variables: [
                "projectId": projectId,
                "environmentId": environmentId,
                "serviceId": serviceId,
                "name": name,
            ],
            token: token
        )
        return data.variableDelete
    }

    // MARK: - Delete Service

    public func deleteService(serviceId: String, token: String) async throws -> Bool {
        let mutation = """
            mutation serviceDelete($id: String!) {
              serviceDelete(id: $id)
            }
            """

        let data: ServiceDeleteData = try await execute(
            query: mutation,
            variables: ["id": serviceId],
            token: token
        )
        return data.serviceDelete
    }

    // MARK: - Fetch Deployments

    public func fetchDeployments(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) async throws -> [Deployment] {
        let query = """
            query deployments($projectId: String!, $environmentId: String!, $serviceId: String!) {
              deployments(
                first: 10
                input: { projectId: $projectId, environmentId: $environmentId, serviceId: $serviceId }
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

        let data: DeploymentsData = try await execute(
            query: query,
            variables: [
                "projectId": projectId,
                "environmentId": environmentId,
                "serviceId": serviceId,
            ],
            token: token
        )
        return data.deployments.edges.map { $0.node }
    }

    // MARK: - Restart Deployment

    public func restartDeployment(deploymentId: String, token: String) async throws -> Bool {
        let mutation = """
            mutation deploymentRestart($id: String!) {
              deploymentRestart(id: $id)
            }
            """

        let data: DeploymentRestartData = try await execute(
            query: mutation,
            variables: ["id": deploymentId],
            token: token
        )
        return data.deploymentRestart
    }

    // MARK: - Redeploy Service (trigger new deployment)

    public func redeployService(environmentId: String, serviceId: String, token: String)
        async throws -> Bool
    {
        let mutation = """
            mutation serviceInstanceRedeploy($environmentId: String!, $serviceId: String!) {
              serviceInstanceRedeploy(environmentId: $environmentId, serviceId: $serviceId)
            }
            """

        let data: ServiceRedeployData = try await execute(
            query: mutation,
            variables: ["environmentId": environmentId, "serviceId": serviceId],
            token: token
        )
        return data.serviceInstanceRedeploy
    }

    // MARK: - Private Methods

    private func execute<T: Decodable>(
        query: String, variables: [String: String], token: String
    ) async throws -> T {
        guard let url = URL(string: baseURL) else {
            throw RailwayError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            GraphQLRequest(query: query, variables: variables))

        let response: GraphQLResponse<T>
        do {
            let (data, urlResponse) = try await session.data(for: request)

            try validate(urlResponse, body: data)
            response = try JSONDecoder().decode(GraphQLResponse<T>.self, from: data)
        } catch let error as RailwayError {
            throw error
        } catch let error as DecodingError {
            throw RailwayError.decodingError(error)
        } catch {
            throw RailwayError.networkError(error)
        }

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError.graphQLError(errors.map { $0.message }.joined(separator: ", "))
        }

        guard let data = response.data else {
            throw RailwayError.unknown
        }

        return data
    }

    private func validate(_ response: URLResponse, body: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RailwayError.unknown
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw RailwayError.unauthorized
        case 429:
            throw RailwayError.rateLimited(
                retryAfter: httpResponse.value(forHTTPHeaderField: "Retry-After"))
        default:
            // A failed response has no data to decode. Only its first error message is useful.
            let errors = try? JSONDecoder().decode(GraphQLResponse<Never>.self, from: body).errors
            throw RailwayError.httpStatus(
                httpResponse.statusCode, message: errors?.first?.message)
        }
    }
}
