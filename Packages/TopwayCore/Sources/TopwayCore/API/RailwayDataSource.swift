/// The Railway reads and actions that the app uses.
///
/// `RailwayClient` sends them to Railway. `SampleDataSource` keeps them in memory.
public protocol RailwayDataSource: Sendable {
    func fetchProjects(workspaceId: String, token: String) async throws -> [Project]

    func createService(projectId: String, repo: String, token: String) async throws -> String

    func createServiceWithImage(projectId: String, image: String, token: String) async throws
        -> String

    func fetchVariables(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) async throws -> [String: String]

    func deleteProject(projectId: String, token: String) async throws -> Bool

    func upsertVariable(
        projectId: String, environmentId: String, serviceId: String, name: String, value: String,
        token: String
    ) async throws -> Bool

    func deleteVariable(
        projectId: String, environmentId: String, serviceId: String, name: String, token: String
    ) async throws -> Bool

    func deleteService(serviceId: String, token: String) async throws -> Bool

    func fetchDeployments(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) async throws -> [Deployment]

    func restartDeployment(deploymentId: String, token: String) async throws -> Bool

    func redeployService(environmentId: String, serviceId: String, token: String)
        async throws -> Bool

    /// Gives the CPU, memory and network samples of a service in one environment.
    func fetchMetrics(
        environmentId: String, serviceId: String, window: MetricWindow, token: String
    ) async throws -> ServiceMetrics

    /// Gives the latest lines, then new lines while they arrive.
    /// Cancel the consumer task to stop the stream.
    func logs(_ kind: LogKind, deploymentId: String, token: String)
        -> AsyncThrowingStream<LogEvent, any Error>
}
