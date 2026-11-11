import Foundation
import SwiftUI
import TopwayCore

@MainActor
@Observable
class AppState {
    // MARK: - Published Properties

    var projects: [Project] = []
    var isLoading = false
    var errorMessage: String?
    var pendingConfirmation: ConfirmationRequest?
    var isRunningConfirmation = false
    /// Sample mode shows the data of `SampleDataSource`. It never reads or writes the
    /// Keychain token, and it ends when the app quits.
    private(set) var isSampleMode = false

    // MARK: - Persisted Properties

    private static let tokenKey = "railwayToken"

    /// In-memory mirror of the Keychain-backed token. Loaded once in `init` so
    /// the frequently-read `railwayToken` accessor never hits the Keychain on
    /// the hot path, and so SwiftUI can observe changes to it.
    private var tokenStorage: String = ""

    /// Railway API token. Persisted securely in the Keychain (never in
    /// UserDefaults, which is cleartext on disk).
    var railwayToken: String {
        get { tokenStorage }
        set { _ = updateToken(newValue) }
    }

    /// Updates the in-memory token and persists it to the Keychain.
    /// - Returns: whether the Keychain write succeeded, so callers can surface
    ///   a failure instead of silently dropping the token.
    @discardableResult
    func updateToken(_ value: String) -> Bool {
        tokenStorage = value
        return KeychainStore.save(value, for: Self.tokenKey)
    }

    /// Persisted in `UserDefaults`, but held as a stored property so `@Observable`
    /// tracks it. A computed accessor that read `UserDefaults` directly would not
    /// register as a dependency, so views (e.g. `isConfigured` in `MainView`)
    /// wouldn't update when it changed. `didSet` does not fire for the default
    /// value during `init`, so no side effects run at startup.
    var workspaceId: String = UserDefaults.standard.string(forKey: "workspaceId") ?? "" {
        didSet {
            UserDefaults.standard.set(workspaceId, forKey: "workspaceId")
            // The projects of a different workspace must not cause false alerts.
            if workspaceId != oldValue {
                alertSnapshot = nil
            }
        }
    }

    /// Off by default. Turning it on asks for notification permission.
    var alertsEnabled: Bool = UserDefaults.standard.bool(forKey: "alertsEnabled") {
        didSet { UserDefaults.standard.set(alertsEnabled, forKey: "alertsEnabled") }
    }

    /// The projects that send no alerts.
    private(set) var mutedProjectIds = Set(
        UserDefaults.standard.stringArray(forKey: "mutedProjectIds") ?? [])
    {
        didSet {
            UserDefaults.standard.set(mutedProjectIds.sorted(), forKey: "mutedProjectIds")
        }
    }

    var autoRefreshEnabled: Bool = UserDefaults.standard.bool(forKey: "autoRefreshEnabled") {
        didSet {
            UserDefaults.standard.set(autoRefreshEnabled, forKey: "autoRefreshEnabled")
            if autoRefreshEnabled {
                startAutoRefresh()
            } else {
                stopAutoRefresh()
            }
        }
    }

    var autoRefreshInterval: TimeInterval = {
        let interval = UserDefaults.standard.double(forKey: "autoRefreshInterval")
        return interval > 0 ? interval : 30  // Default 30 seconds
    }()
    {
        didSet {
            UserDefaults.standard.set(autoRefreshInterval, forKey: "autoRefreshInterval")
            if autoRefreshEnabled {
                restartAutoRefresh()
            }
        }
    }

    // MARK: - Private Properties

    private var dataSource: any RailwayDataSource = RailwayClient()
    private var refreshTask: Task<Void, Never>?
    /// The message that the latest failed background refresh set.
    private var refreshFailureMessage: String?
    /// Only the latest project load may change the screen. A data source switch also
    /// increases it, so a load from the earlier source is dropped.
    private var latestProjectLoad = 0
    /// The last settled state of each service. It is `nil` before the first load of a data
    /// source or a workspace, so that load gives no alerts.
    private var alertSnapshot: AlertSnapshot?

    // MARK: - Init

    init() {
        // Load the token from the Keychain, migrating any legacy token that an
        // earlier build stored in cleartext UserDefaults.
        if let stored = KeychainStore.read(Self.tokenKey) {
            tokenStorage = stored
        } else if let legacy = UserDefaults.standard.string(forKey: Self.tokenKey),
            !legacy.isEmpty
        {
            // Only drop the cleartext copy once it's safely in the Keychain.
            if KeychainStore.save(legacy, for: Self.tokenKey) {
                UserDefaults.standard.removeObject(forKey: Self.tokenKey)
            }
            tokenStorage = legacy
        }
    }

    // MARK: - Computed Properties

    var isConfigured: Bool {
        isSampleMode || (!railwayToken.isEmpty && !workspaceId.isEmpty)
    }

    var hasError: Bool {
        errorMessage != nil
    }

    var health: HealthSummary {
        HealthSummary(projects: projects)
    }

    // MARK: - Public Methods

    func loadProjects(keepingError: Bool = false) async {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return
        }

        isLoading = true
        if !keepingError {
            errorMessage = nil
        }

        latestProjectLoad += 1
        let load = latestProjectLoad
        do {
            let fetchedProjects = try await dataSource.fetchProjects(
                workspaceId: workspaceId,
                token: railwayToken
            )
            guard load == latestProjectLoad else { return }
            projects = fetchedProjects
            sendAlerts(for: fetchedProjects)
            if let refreshFailureMessage, errorMessage == refreshFailureMessage {
                errorMessage = nil
            }
            refreshFailureMessage = nil
        } catch let error as RailwayError {
            guard load == latestProjectLoad else { return }
            show(error)
            // A cancellation sets no message, so `errorMessage` can belong to a user action.
            if error.errorDescription != nil {
                refreshFailureMessage = keepingError ? errorMessage : nil
            }
        } catch {
            guard load == latestProjectLoad else { return }
            errorMessage = error.localizedDescription
            refreshFailureMessage = keepingError ? errorMessage : nil
        }

        isLoading = false
    }

    func createService(projectId: String, repo: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await dataSource.createService(
                projectId: projectId,
                repo: repo,
                token: railwayToken
            )
            // Refresh projects to show the new service
            await loadProjects()
            return true
        } catch let error as RailwayError {
            show(error)
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func createServiceWithImage(projectId: String, image: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await dataSource.createServiceWithImage(
                projectId: projectId,
                image: image,
                token: railwayToken
            )
            // Refresh projects to show the new service
            await loadProjects()
            return true
        } catch let error as RailwayError {
            show(error)
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    /// Returns `nil` when the fetch fails or is cancelled. An empty array means no variables.
    func fetchVariables(projectId: String, environmentId: String, serviceId: String) async
        -> [EnvironmentVariable]?
    {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return nil
        }

        errorMessage = nil

        do {
            let variables = try await dataSource.fetchVariables(
                projectId: projectId,
                environmentId: environmentId,
                serviceId: serviceId,
                token: railwayToken
            )
            return variables.map { EnvironmentVariable(name: $0.key, value: $0.value) }
                .sorted { $0.name < $1.name }
        } catch let error as RailwayError {
            show(error)
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func deleteProject(projectId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let success = try await dataSource.deleteProject(
                projectId: projectId,
                token: railwayToken
            )
            // Reconcile with the server regardless of the result: a project that
            // was already deleted (or is mid-deletion) then drops out of the
            // refreshed list instead of lingering in the UI.
            await loadProjects()
            if !success {
                errorMessage = "Railway did not delete the project. Try again."
            }
            return success
        } catch let error as RailwayError {
            await loadProjects()
            show(error)
            return false
        } catch {
            let description = error.localizedDescription
            await loadProjects()
            errorMessage = description
            return false
        }
    }

    private func show(_ error: RailwayError) {
        if case .cancelled = error { return }
        errorMessage = error.errorDescription
    }

    func clearError() {
        errorMessage = nil
        refreshFailureMessage = nil
    }

    // MARK: - Sample Mode

    func enterSampleMode() {
        switchDataSource(to: SampleDataSource(), isSampleMode: true)
    }

    func exitSampleMode() {
        guard isSampleMode else { return }
        switchDataSource(to: RailwayClient(), isSampleMode: false)
    }

    /// Removes the projects of the earlier data source. `MainView` then loads the new projects.
    private func switchDataSource(to source: any RailwayDataSource, isSampleMode: Bool) {
        dataSource = source
        latestProjectLoad += 1
        alertSnapshot = nil
        self.isSampleMode = isSampleMode
        projects = []
        isLoading = false
        pendingConfirmation = nil
        clearError()
        restartAutoRefresh()
    }

    // MARK: - Alerts

    func toggleMute(projectId: String) {
        if mutedProjectIds.contains(projectId) {
            mutedProjectIds.remove(projectId)
        } else {
            mutedProjectIds.insert(projectId)
        }
    }

    /// Compares the new statuses with the earlier load and sends the alerts.
    /// The snapshot changes also when alerts are off, so turning them on gives no old alerts.
    private func sendAlerts(for projects: [Project]) {
        let statuses = projects.flatMap(\.serviceStatuses)
        guard var snapshot = alertSnapshot else {
            alertSnapshot = AlertSnapshot(statuses: statuses)
            return
        }
        let alerts = snapshot.update(with: statuses, mutedProjectIds: mutedProjectIds)
        alertSnapshot = snapshot
        guard alertsEnabled, !alerts.isEmpty else { return }
        let isSampleMode = isSampleMode
        Task {
            do {
                try await AlertNotifier.send(alerts, isSampleMode: isSampleMode)
            } catch {
                errorMessage = "Topway cannot show an alert. \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Confirmation

    /// Runs the action at once for low harm. Other levels wait for the user in the dialog.
    func confirm(_ request: ConfirmationRequest) {
        guard request.harm.needsDialog else {
            Task { await request.perform() }
            return
        }
        pendingConfirmation = request
    }

    func cancelConfirmation() {
        guard !isRunningConfirmation else { return }
        pendingConfirmation = nil
    }

    /// Keeps the dialog open with a progress indicator until the action ends.
    func runPendingConfirmation() {
        guard let request = pendingConfirmation, !isRunningConfirmation else { return }
        isRunningConfirmation = true
        Task {
            await request.perform()
            isRunningConfirmation = false
            pendingConfirmation = nil
        }
    }

    // MARK: - Variable Management

    func upsertVariable(
        projectId: String, environmentId: String, serviceId: String, name: String, value: String
    ) async -> Bool {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return false
        }

        errorMessage = nil

        do {
            let success = try await dataSource.upsertVariable(
                projectId: projectId,
                environmentId: environmentId,
                serviceId: serviceId,
                name: name,
                value: value,
                token: railwayToken
            )
            if !success {
                errorMessage = "Railway did not save the variable. Try again."
            }
            return success
        } catch let error as RailwayError {
            show(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteVariable(projectId: String, environmentId: String, serviceId: String, name: String)
        async -> Bool
    {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return false
        }

        errorMessage = nil

        do {
            let success = try await dataSource.deleteVariable(
                projectId: projectId,
                environmentId: environmentId,
                serviceId: serviceId,
                name: name,
                token: railwayToken
            )
            if !success {
                errorMessage = "Railway did not delete the variable. Try again."
            }
            return success
        } catch let error as RailwayError {
            show(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Service Management

    func deleteService(serviceId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let success = try await dataSource.deleteService(
                serviceId: serviceId,
                token: railwayToken
            )
            if success {
                await loadProjects()
            } else {
                errorMessage = "Railway did not delete the service. Try again."
                isLoading = false
            }
            return success
        } catch let error as RailwayError {
            show(error)
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Deployment Management

    func fetchDeployments(projectId: String, environmentId: String, serviceId: String) async
        -> [Deployment]
    {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return []
        }

        errorMessage = nil

        do {
            let deployments = try await dataSource.fetchDeployments(
                projectId: projectId,
                environmentId: environmentId,
                serviceId: serviceId,
                token: railwayToken
            )
            return deployments
        } catch let error as RailwayError {
            show(error)
            return []
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    func restartDeployment(deploymentId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return false
        }

        errorMessage = nil

        do {
            let success = try await dataSource.restartDeployment(
                deploymentId: deploymentId,
                token: railwayToken
            )
            if !success {
                errorMessage = "Railway did not restart the deployment. Try again."
            }
            return success
        } catch let error as RailwayError {
            show(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func redeployService(environmentId: String, serviceId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Add your API token and Workspace ID in Settings."
            return false
        }

        errorMessage = nil

        do {
            let success = try await dataSource.redeployService(
                environmentId: environmentId,
                serviceId: serviceId,
                token: railwayToken
            )
            if !success {
                errorMessage = "Railway did not start the redeploy. Try again."
            }
            return success
        } catch let error as RailwayError {
            show(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        guard autoRefreshEnabled && isConfigured else { return }

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.autoRefreshInterval ?? 30))
                guard !Task.isCancelled else { break }
                // A background refresh must not remove the error of a failed action.
                await self?.loadProjects(keepingError: true)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func restartAutoRefresh() {
        stopAutoRefresh()
        startAutoRefresh()
    }

    /// Runs at app launch. Loads the projects once, so the menu bar shows the health at once.
    func initializeAutoRefresh() async {
        guard isConfigured else { return }
        startAutoRefresh()
        await loadProjects()
    }
}
