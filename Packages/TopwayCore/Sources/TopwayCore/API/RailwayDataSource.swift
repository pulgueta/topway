/// The Railway reads and actions that the app uses.
///
/// `RailwayClient` sends them to Railway. `SampleDataSource` keeps them in memory.
public protocol RailwayDataSource: Sendable {
    func fetchProjects(workspaceId: String, token: String) async throws -> [Project]

    func createService(projectId: String, repo: String, token: String) async throws -> String

    func createServiceWithImage(projectId: String, image: String, token: String) async throws
        -> String

    /// Gives the variables of a service unrendered: a reference keeps its template, for
    /// example `${{ postgres.DATABASE_URL }}`.
    func fetchVariables(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) async throws -> [String: String]

    /// Gives the unrendered shared variables of an environment and the unrendered variables
    /// of each service in `serviceIds`, in one request.
    func fetchProjectVariables(
        projectId: String, environmentId: String, serviceIds: [String], token: String
    ) async throws -> ProjectVariables

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

    /// Makes an environment in a project and gives its ID. With `sourceEnvironmentId`,
    /// Railway copies the services, the variables and the settings of that environment.
    func createEnvironment(
        projectId: String, name: String, sourceEnvironmentId: String?, token: String
    ) async throws -> String

    func deleteEnvironment(environmentId: String, token: String) async throws -> Bool

    /// Deploys an earlier deployment again.
    func rollbackDeployment(deploymentId: String, token: String) async throws -> Bool

    /// Stops a build or a deploy that is in progress.
    func cancelDeployment(deploymentId: String, token: String) async throws -> Bool

    /// Removes a deployment. The service then stops in the environment of the deployment.
    func removeDeployment(deploymentId: String, token: String) async throws -> Bool

    /// Gives the name of a service and its settings in one environment.
    func fetchServiceSettings(environmentId: String, serviceId: String, token: String)
        async throws -> ServiceSettings

    /// Saves the changed settings. A new name applies to all environments, and the other
    /// settings to one environment. Returns `false` when Railway did not save them.
    func updateServiceSettings(
        _ changes: ServiceSettingsChanges, environmentId: String, serviceId: String, token: String
    ) async throws -> Bool

    /// Gives the Railway domains, then the custom domains, of a service in one environment.
    func fetchDomains(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) async throws -> [Domain]

    /// Makes a public domain of Railway for the service.
    func createRailwayDomain(environmentId: String, serviceId: String, token: String)
        async throws -> Domain

    /// Adds a domain of the user. The answer has the DNS records that the user must set.
    func createCustomDomain(
        projectId: String, environmentId: String, serviceId: String, name: String, token: String
    ) async throws -> Domain

    func deleteDomain(id: String, kind: DomainKind, token: String) async throws -> Bool

    /// Asks Railway to add a database service to a project from its template, and to
    /// start it in one environment. When this returns, Railway accepted the deploy.
    /// Returns the ID of the workflow that makes the service, or `nil` when Railway made
    /// it at once.
    func deployDatabase(
        _ template: DatabaseTemplate, projectId: String, environmentId: String, token: String
    ) async throws -> String?

    /// Waits for the workflow of an accepted deploy. Throws only when Railway says that
    /// the workflow failed, or when the task is cancelled. A request that fails gives
    /// `pending`, because the deploy can still end correctly.
    func waitForDatabase(workflowId: String, token: String) async throws
        -> DatabaseDeployResult

    /// Gives the CPU, memory and network samples of a service in one environment.
    func fetchMetrics(
        environmentId: String, serviceId: String, window: MetricWindow, token: String
    ) async throws -> ServiceMetrics

    /// Gives the cost and the resource usage of the current billing period of a workspace.
    func fetchSpend(workspaceId: String, token: String) async throws -> Spend

    /// Gives the incident that Railway reports as open, or `nil`. The request has no token
    /// and no data of the user.
    func fetchOpenIncident() async throws -> PlatformIncident?

    /// Gives the latest lines, then new lines while they arrive.
    /// Cancel the consumer task to stop the stream.
    func logs(_ kind: LogKind, deploymentId: String, token: String)
        -> AsyncThrowingStream<LogEvent, any Error>
}
