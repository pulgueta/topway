import Foundation
import SwiftUI

@MainActor
@Observable
class AppState {
    // MARK: - Published Properties
    
    var projects: [Project] = []
    var isLoading = false
    var errorMessage: String?

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
        didSet { UserDefaults.standard.set(workspaceId, forKey: "workspaceId") }
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
        return interval > 0 ? interval : 30 // Default 30 seconds
    }() {
        didSet {
            UserDefaults.standard.set(autoRefreshInterval, forKey: "autoRefreshInterval")
            if autoRefreshEnabled {
                restartAutoRefresh()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let client = RailwayClient()
    private var refreshTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        // Load the token from the Keychain, migrating any legacy token that an
        // earlier build stored in cleartext UserDefaults.
        if let stored = KeychainStore.read(Self.tokenKey) {
            tokenStorage = stored
        } else if let legacy = UserDefaults.standard.string(forKey: Self.tokenKey),
                  !legacy.isEmpty {
            // Only drop the cleartext copy once it's safely in the Keychain.
            if KeychainStore.save(legacy, for: Self.tokenKey) {
                UserDefaults.standard.removeObject(forKey: Self.tokenKey)
            }
            tokenStorage = legacy
        }
    }

    // MARK: - Computed Properties
    
    var isConfigured: Bool {
        !railwayToken.isEmpty && !workspaceId.isEmpty
    }
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    // MARK: - Public Methods
    
    func loadProjects() async {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedProjects = try await client.fetchProjects(
                workspaceId: workspaceId,
                token: railwayToken
            )
            projects = fetchedProjects
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createService(projectId: String, repo: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await client.createService(
                projectId: projectId,
                repo: repo,
                token: railwayToken
            )
            // Refresh projects to show the new service
            await loadProjects()
            return true
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
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
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await client.createServiceWithImage(
                projectId: projectId,
                image: image,
                token: railwayToken
            )
            // Refresh projects to show the new service
            await loadProjects()
            return true
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func fetchVariables(projectId: String, environmentId: String, serviceId: String) async -> [EnvironmentVariable] {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return []
        }
        
        do {
            let variables = try await client.fetchVariables(
                projectId: projectId,
                environmentId: environmentId,
                serviceId: serviceId,
                token: railwayToken
            )
            return variables.map { EnvironmentVariable(name: $0.key, value: $0.value) }
                .sorted { $0.name < $1.name }
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
            return []
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }
    
    func deleteProject(projectId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await client.deleteProject(
                projectId: projectId,
                token: railwayToken
            )
            // Reconcile with the server regardless of the result: a project that
            // was already deleted (or is mid-deletion) then drops out of the
            // refreshed list instead of lingering in the UI.
            await loadProjects()
            return success
        } catch let error as RailwayError {
            let description = error.errorDescription
            await loadProjects()
            errorMessage = description
            return false
        } catch {
            let description = error.localizedDescription
            await loadProjects()
            errorMessage = description
            return false
        }
    }
    
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Variable Management
    
    func upsertVariable(projectId: String, environmentId: String, serviceId: String, name: String, value: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return false
        }
        
        do {
            let success = try await client.upsertVariable(
                projectId: projectId,
                environmentId: environmentId,
                serviceId: serviceId,
                name: name,
                value: value,
                token: railwayToken
            )
            return success
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func deleteVariable(projectId: String, environmentId: String, serviceId: String, name: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return false
        }
        
        do {
            let success = try await client.deleteVariable(
                projectId: projectId,
                environmentId: environmentId,
                serviceId: serviceId,
                name: name,
                token: railwayToken
            )
            return success
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Service Management
    
    func deleteService(serviceId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await client.deleteService(
                serviceId: serviceId,
                token: railwayToken
            )
            if success {
                await loadProjects() // resets isLoading
            } else {
                isLoading = false
            }
            return success
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Deployment Management
    
    func fetchDeployments(projectId: String, environmentId: String, serviceId: String) async -> [Deployment] {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return []
        }
        
        do {
            let deployments = try await client.fetchDeployments(
                projectId: projectId,
                environmentId: environmentId,
                serviceId: serviceId,
                token: railwayToken
            )
            return deployments
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
            return []
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }
    
    func restartDeployment(deploymentId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return false
        }
        
        do {
            let success = try await client.restartDeployment(
                deploymentId: deploymentId,
                token: railwayToken
            )
            return success
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func redeployService(environmentId: String, serviceId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = "Please configure your API token and Workspace ID in settings."
            return false
        }
        
        do {
            let success = try await client.redeployService(
                environmentId: environmentId,
                serviceId: serviceId,
                token: railwayToken
            )
            return success
        } catch let error as RailwayError {
            errorMessage = error.errorDescription
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
                await self?.loadProjects()
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
    
    func initializeAutoRefresh() {
        if autoRefreshEnabled && isConfigured {
            startAutoRefresh()
        }
    }
}
