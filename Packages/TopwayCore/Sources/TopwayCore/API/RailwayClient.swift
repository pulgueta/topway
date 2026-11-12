import Foundation

public struct RailwayClient: RailwayDataSource {
    private let baseURL = "https://backboard.railway.com/graphql/v2"
    private let session: URLSession
    private let sleep: @Sendable (Duration) async throws -> Void
    private let socket: GraphQLWebSocket
    private let now: @Sendable () -> Date

    /// - Parameters:
    ///   - sleep: Waits between polls and before a reconnect. Tests replace it.
    ///   - now: Gives the current date. The start of a metrics time range comes from it.
    public init(
        session: URLSession = .shared,
        sleep: @escaping @Sendable (Duration) async throws -> Void = {
            try await Task.sleep(for: $0)
        },
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.init(
            session: session, sleep: sleep, socket: GraphQLWebSocket(session: session), now: now)
    }

    /// Tests pass a socket with scripted frames.
    init(
        session: URLSession, sleep: @escaping @Sendable (Duration) async throws -> Void,
        socket: GraphQLWebSocket, now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.session = session
        self.sleep = sleep
        self.socket = socket
        self.now = now
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
                            deletedAt
                            serviceInstances {
                              edges {
                                node {
                                  serviceId
                                  deletedAt
                                  latestDeployment {
                                    id
                                    status
                                    staticUrl
                                    createdAt
                                  }
                                }
                              }
                            }
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
            mutation ServiceCreate($projectId: String!, $repo: String!) {
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
            mutation ServiceCreate($projectId: String!, $image: String!) {
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
            query Variables($projectId: String!, $environmentId: String!, $serviceId: String!) {
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
            mutation ProjectDelete($id: String!) {
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
            mutation VariableUpsert(
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
            mutation VariableDelete(
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
            mutation ServiceDelete($id: String!) {
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
            query Deployments($projectId: String!, $environmentId: String!, $serviceId: String!) {
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
                    canRollback
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
            mutation DeploymentRestart($id: String!) {
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
            mutation ServiceInstanceRedeploy($environmentId: String!, $serviceId: String!) {
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

    // MARK: - Metrics

    public func fetchMetrics(
        environmentId: String, serviceId: String, window: MetricWindow, token: String
    ) async throws -> ServiceMetrics {
        // The measurements and the sample rate are constants of Topway, not user input.
        let measurements = MetricKind.allCases.map(\.rawValue).joined(separator: ", ")
        let query = """
            query Metrics($environmentId: String!, $serviceId: String!, $startDate: DateTime!) {
              metrics(
                environmentId: $environmentId
                serviceId: $serviceId
                startDate: $startDate
                measurements: [\(measurements)]
                sampleRateSeconds: \(window.sampleRateSeconds)
              ) {
                measurement
                values {
                  ts
                  value
                }
              }
            }
            """

        let data: MetricsData = try await execute(
            query: query,
            variables: [
                "environmentId": environmentId,
                "serviceId": serviceId,
                "startDate": window.startDate(now: now()).formatted(.iso8601),
            ],
            token: token
        )
        return ServiceMetrics(results: data.metrics)
    }

    // MARK: - Spend

    /// Sends two requests: the usage query needs the dates of the billing period, and the
    /// first answer gives them.
    public func fetchSpend(workspaceId: String, token: String) async throws -> Spend {
        let customerQuery = """
            query Spend($workspaceId: String!) {
              workspace(workspaceId: $workspaceId) {
                customer {
                  currentUsage
                  billingPeriod {
                    start
                    end
                  }
                  usageLimit {
                    softLimit
                    hardLimit
                    isOverLimit
                  }
                }
              }
            }
            """
        let spendData: SpendData = try await execute(
            query: customerQuery, variables: ["workspaceId": workspaceId], token: token)
        let customer = spendData.workspace.customer

        // The measurements are constants of Topway, not user input. `includeDeleted` adds
        // the deleted projects and services, which the cost of Railway also includes.
        let measurements = UsageKind.allCases.map(\.rawValue).joined(separator: ", ")
        let usageQuery = """
            query Usage($workspaceId: String!, $startDate: DateTime!, $endDate: DateTime!) {
              usage(
                workspaceId: $workspaceId
                startDate: $startDate
                endDate: $endDate
                measurements: [\(measurements)]
                includeDeleted: true
              ) {
                measurement
                value
              }
            }
            """
        let usageData: UsageData = try await execute(
            query: usageQuery,
            variables: [
                "workspaceId": workspaceId,
                "startDate": customer.billingPeriod.start.formatted(.iso8601),
                "endDate": min(now(), customer.billingPeriod.end).formatted(.iso8601),
            ],
            token: token
        )
        return Spend(customer: customer, usage: usageData.usage)
    }

    // MARK: - Platform Status

    /// Railway answers this query with no token, so the request has no `Authorization`
    /// header. It tells Railway nothing about the user.
    public func fetchOpenIncident() async throws -> PlatformIncident? {
        let query = """
            query PlatformStatus {
              platformStatus {
                incident {
                  id
                  message
                  status
                  url
                }
              }
            }
            """

        let data: PlatformStatusData = try await execute(query: query, variables: [:], token: nil)
        return data.platformStatus.openIncident
    }

    // MARK: - Logs

    private static let pollInterval = Duration.seconds(5)
    /// 12 polls of 5 seconds: polling tries the socket again every 60 seconds.
    private static let pollsBeforeSocketTry = 12

    /// Uses the WebSocket subscription. `LogRecovery` decides what to do when the socket
    /// fails: connect again with a backoff, poll, or stop. Polling reads the matching query
    /// every 5 seconds and tries the socket again every 60 seconds. A network error in
    /// polling does not stop the stream. `LogDeduplicator` removes the lines that a reconnect
    /// or a poll gives again.
    public func logs(_ kind: LogKind, deploymentId: String, token: String)
        -> AsyncThrowingStream<LogEvent, any Error>
    {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await streamLogs(
                        kind, deploymentId: deploymentId, token: token, to: continuation)
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func streamLogs(
        _ kind: LogKind, deploymentId: String, token: String,
        to continuation: AsyncThrowingStream<LogEvent, any Error>.Continuation
    ) async throws {
        let variables = ["deploymentId": deploymentId]
        var deduplicator = LogDeduplicator(capacity: 1_000)
        func yield(_ lines: [LogLine]) {
            let new = deduplicator.newLines(in: lines)
            if !new.isEmpty {
                continuation.yield(.lines(new))
            }
        }

        let subscription = GraphQLRequest(
            query: Self.logsDocument(kind, operation: "subscription"), variables: variables)
        let query = Self.logsDocument(kind, operation: "query")
        var recovery = LogRecovery()
        while true {
            do {
                for try await event in socket.subscribe(
                    subscription, token: token, as: LogsData.self)
                {
                    switch event {
                    case .connected:
                        recovery.connected()
                        continuation.yield(.connection(.live))
                    case .payload(let data):
                        recovery.payloadReceived()
                        yield(data.lines)
                    }
                }
                // Railway ended the subscription, or the consumer stopped the stream.
                return
            } catch let error as RailwayError {
                switch recovery.step(after: error) {
                case .fail:
                    throw error
                case .reconnect(let delay):
                    continuation.yield(.connection(.reconnecting))
                    try await sleep(delay)
                    continue
                case .poll:
                    break
                }
            }

            // Poll until the next socket try. One request each 5 seconds.
            continuation.yield(.connection(.polling))
            for _ in 0..<Self.pollsBeforeSocketTry {
                do {
                    let data: LogsData = try await execute(
                        query: query, variables: variables, token: token)
                    yield(data.lines)
                    if let deployment = data.deployment, !deployment.isBuildRunning {
                        // A finished build log gets no more lines.
                        return
                    }
                } catch RailwayError.networkError {
                    // A short network problem. Try again at the next interval.
                }
                try await sleep(Self.pollInterval)
            }
            recovery.retryingFromPolling()
        }
    }

    /// The subscription and the query have the same arguments and fields. The build log
    /// query also reads the deployment status, so polling can stop when the build ends.
    private static func logsDocument(_ kind: LogKind, operation: String) -> String {
        let status =
            kind == .build && operation == "query"
            ? """

              deployment(id: $deploymentId) {
                id
                status
                staticUrl
                createdAt
              }
            """ : ""
        return """
            \(operation) Logs($deploymentId: String!) {
              lines: \(kind.fieldName)(deploymentId: $deploymentId, limit: 500) {
                timestamp
                message
                severity
              }\(status)
            }
            """
    }

    // MARK: - Private Methods

    /// - Parameter token: `nil` sends no `Authorization` header.
    func execute<T: Decodable>(
        query: String, variables: [String: String], token: String?
    ) async throws -> T {
        guard let url = URL(string: baseURL) else {
            throw RailwayError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
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
            throw RailwayError(transportFailure: error)
        }

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayError(graphQLErrors: errors)
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
