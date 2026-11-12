import Foundation

/// Keeps sample Railway data in memory, so the app can run with no token.
/// It sends no network requests. Actions change the data, and later reads show the change.
public actor SampleDataSource: RailwayDataSource {
    let now: @Sendable () -> Date
    private let sleep: @Sendable (Duration) async throws -> Void
    var projects: [Project]
    /// The deployments of each environment and service, newest first.
    var deployments: [String: [Deployment]] = [:]
    var deploymentCount = 0
    private var serviceCount = 0
    var environmentCount = 0
    /// The variables of each environment and service.
    var variables = seedVariables
    /// The shared variables of each environment.
    var sharedVariables = seedSharedVariables
    /// The settings that the user saved, for each environment and service.
    var settings: [String: ServiceSettings] = [:]
    /// The domains of each environment and service.
    var domains = seedDomains
    var domainCount = 0

    /// - Parameters:
    ///   - now: Gives the current date. The deployment and log dates come from it.
    ///   - sleep: Waits between sample log lines. Tests replace it.
    public init(
        now: @escaping @Sendable () -> Date = { .now },
        sleep: @escaping @Sendable (Duration) async throws -> Void = {
            try await Task.sleep(for: $0)
        }
    ) {
        self.now = now
        self.sleep = sleep
        projects = Self.seedProjects
        let date = now()
        var count = 0
        for seed in Self.seedDeployments {
            deployments[Self.key(seed.environmentId, seed.serviceId)] = seed.deployments.map {
                count += 1
                return Self.makeDeployment(
                    number: count, status: $0.status,
                    createdAt: date - TimeInterval($0.age * 60))
            }
        }
        deploymentCount = count
    }

    /// The sample data has one workspace, so this method ignores `workspaceId` and `token`.
    /// Each environment gets the latest deployment of each service, as Railway gives it.
    public func fetchProjects(workspaceId: String, token: String) -> [Project] {
        projects.map { project in
            let environments = project.environmentList.map { environment in
                RailwayEnvironment(
                    id: environment.id, name: environment.name,
                    instances: project.serviceList.compactMap { service in
                        guard
                            let latest = deployments[Self.key(environment.id, service.id)]?.first
                        else { return nil }
                        return ServiceInstance(serviceId: service.id, latestDeployment: latest)
                    })
            }
            return Project(
                id: project.id, name: project.name, services: project.services,
                environments: EnvironmentConnection(
                    edges: environments.map { EnvironmentEdge(node: $0) }))
        }
    }

    /// Names the service after the repository, as Railway does.
    public func createService(projectId: String, repo: String, token: String) throws -> String {
        try addService(named: Self.serviceName(from: repo), toProject: projectId)
    }

    /// Names the service after the image, as Railway does.
    public func createServiceWithImage(projectId: String, image: String, token: String) throws
        -> String
    {
        try addService(named: Self.serviceName(from: image), toProject: projectId)
    }

    public func fetchVariables(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) -> [String: String] {
        variables[Self.key(environmentId, serviceId)] ?? [:]
    }

    /// Returns `false` when the project does not exist.
    public func deleteProject(projectId: String, token: String) -> Bool {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else { return false }
        projects.remove(at: index)
        return true
    }

    public func upsertVariable(
        projectId: String, environmentId: String, serviceId: String, name: String, value: String,
        token: String
    ) -> Bool {
        variables[Self.key(environmentId, serviceId), default: [:]][name] = value
        return true
    }

    /// Returns `false` when the variable does not exist.
    public func deleteVariable(
        projectId: String, environmentId: String, serviceId: String, name: String, token: String
    ) -> Bool {
        variables[Self.key(environmentId, serviceId)]?.removeValue(forKey: name) != nil
    }

    /// Returns `false` when the service does not exist.
    public func deleteService(serviceId: String, token: String) -> Bool {
        guard
            let index = projects.firstIndex(where: {
                $0.serviceList.contains { $0.id == serviceId }
            })
        else { return false }
        replaceServices(
            inProjectAt: index, with: projects[index].serviceList.filter { $0.id != serviceId })
        return true
    }

    public func fetchDeployments(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) -> [Deployment] {
        deployments[Self.key(environmentId, serviceId)] ?? []
    }

    /// Makes the deployment run again.
    public func restartDeployment(deploymentId: String, token: String) -> Bool {
        for (key, list) in deployments {
            guard let index = list.firstIndex(where: { $0.id == deploymentId }) else { continue }
            deployments[key]?[index] = Self.changing(list[index], to: "SUCCESS")
            return true
        }
        return false
    }

    /// Adds a running deployment, dated now. The earlier running deployment becomes removed.
    public func redeployService(environmentId: String, serviceId: String, token: String) -> Bool {
        startDeployment(key: Self.key(environmentId, serviceId))
        return true
    }

    public func fetchMetrics(
        environmentId: String, serviceId: String, window: MetricWindow, token: String
    ) -> ServiceMetrics {
        Self.sampleMetrics(
            environmentId: environmentId, serviceId: serviceId, window: window, now: now())
    }

    public func fetchSpend(workspaceId: String, token: String) -> Spend {
        // The billing period started 12 days before now and has 30 days.
        let start = now() - 12 * 86_400
        return Spend(
            cost: 23.47, periodStart: start, periodEnd: start + 30 * 86_400, softLimit: 50,
            hardLimit: 100, isOverLimit: false,
            usage: [
                UsageTotal(kind: .cpu, value: 9_400), UsageTotal(kind: .memory, value: 31_000),
                UsageTotal(kind: .egress, value: 14.2), UsageTotal(kind: .volume, value: 86_400),
            ])
    }

    /// The message says that the incident is a sample, so it does not look like a real
    /// outage. The link is the Railway status page, which shows the real status.
    public nonisolated func fetchOpenIncident() -> PlatformIncident? {
        PlatformIncident(
            id: "sample-incident", message: "Sample incident: builds are slow.",
            status: "MONITORING", url: PlatformIncident.statusPage.absoluteString)
    }

    /// The same lines for each deployment. Build logs end after the build steps.
    /// Deploy logs give the start lines, then one line every 2 seconds until the stream stops.
    /// Each line is 1 second after the line before it.
    public nonisolated func logs(_ kind: LogKind, deploymentId: String, token: String)
        -> AsyncThrowingStream<LogEvent, any Error>
    {
        let start = now()
        let sleep = sleep
        func line(_ seed: (severity: String, message: String), second: Int) -> LogLine {
            LogLine(
                timestamp: (start + TimeInterval(second)).formatted(.iso8601),
                message: seed.message, severity: seed.severity)
        }
        return AsyncThrowingStream { continuation in
            let task = Task {
                continuation.yield(.connection(.live))
                let seeds = kind == .build ? Self.seedBuildLogs : Self.seedDeployLogs
                continuation.yield(
                    .lines(
                        seeds.enumerated().map {
                            line($0.element, second: $0.offset - seeds.count)
                        }))
                guard kind == .deploy else {
                    continuation.finish()
                    return
                }
                var second = 1
                do {
                    while true {
                        try await sleep(.seconds(2))
                        let seed = Self.seedLiveLogs[(second - 1) % Self.seedLiveLogs.count]
                        continuation.yield(.lines([line(seed, second: second)]))
                        second += 1
                    }
                } catch {
                    // Only a cancelled sleep throws.
                    continuation.finish()
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Private Methods

    func addService(named name: String, toProject projectId: String) throws -> String {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else {
            throw RailwayError.graphQLError("Project not found.")
        }
        serviceCount += 1
        let service = Service(id: "service-\(serviceCount)", name: name)
        replaceServices(inProjectAt: index, with: projects[index].serviceList + [service])
        return service.id
    }

    /// Adds a running deployment, dated now. The deployment that ran becomes removed, and a
    /// rollback to it is then possible.
    func startDeployment(key: String) {
        let earlier = (deployments[key] ?? []).map {
            $0.status == "SUCCESS" ? Self.changing($0, to: "REMOVED", canRollback: true) : $0
        }
        deploymentCount += 1
        let deployment = Self.makeDeployment(
            number: deploymentCount, status: "SUCCESS", createdAt: now())
        deployments[key] = [deployment] + earlier
    }

    func replaceServices(inProjectAt index: Int, with services: [Service]) {
        let project = projects[index]
        projects[index] = Project(
            id: project.id, name: project.name,
            services: ServiceConnection(edges: services.map { ServiceEdge(node: $0) }),
            environments: project.environments)
    }

    /// Takes the last path part without the tag: `ghcr.io/acme/search:1.2` gives `search`.
    private static func serviceName(from source: String) -> String {
        let last = source.split(separator: "/").last ?? Substring(source)
        return String(last.split(separator: ":").first ?? last)
    }

    static func key(_ environmentId: String, _ serviceId: String) -> String {
        "\(environmentId)/\(serviceId)"
    }

    /// The sample deployments have no URL, so the app opens no unknown site. A removed
    /// sample deployment ran before, so a rollback to it is possible.
    private static func makeDeployment(number: Int, status: String, createdAt: Date)
        -> Deployment
    {
        Deployment(
            id: "deployment-\(number)", status: status, staticUrl: nil,
            createdAt: createdAt.formatted(.iso8601), canRollback: status == "REMOVED")
    }

    static func changing(
        _ deployment: Deployment, to status: String, canRollback: Bool = false
    ) -> Deployment {
        Deployment(
            id: deployment.id, status: status, staticUrl: deployment.staticUrl,
            createdAt: deployment.createdAt, canRollback: canRollback)
    }
}
