import Foundation
import SwiftUI

@MainActor
@Observable
class AppState {
    // MARK: - Published Properties
    
    var projects: [Project] = []
    var isLoading = false
    var errorMessage: String?
    var showingSettings = false
    var showingAddService = false
    var selectedProjectId: String?
    
    // MARK: - Persisted Properties (using UserDefaults directly for @Observable)
    
    var railwayToken: String {
        get { UserDefaults.standard.string(forKey: "railwayToken") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "railwayToken") }
    }
    
    var workspaceId: String {
        get { UserDefaults.standard.string(forKey: "workspaceId") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "workspaceId") }
    }
    
    var autoRefreshEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "autoRefreshEnabled") }
        set { 
            UserDefaults.standard.set(newValue, forKey: "autoRefreshEnabled")
            if newValue {
                startAutoRefresh()
            } else {
                stopAutoRefresh()
            }
        }
    }
    
    var autoRefreshInterval: TimeInterval {
        get { 
            let interval = UserDefaults.standard.double(forKey: "autoRefreshInterval")
            return interval > 0 ? interval : 30.0 // Default 30 seconds
        }
        set { 
            UserDefaults.standard.set(newValue, forKey: "autoRefreshInterval")
            if autoRefreshEnabled {
                restartAutoRefresh()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let client = RailwayClient()
    private var refreshTask: Task<Void, Never>?
    
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
            if success {
                // Refresh projects to reflect deletion
                await loadProjects()
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
    
    func clearError() {
        errorMessage = nil
    }
    
    func openSettings() {
        showingSettings = true
    }
    
    func closeSettings() {
        showingSettings = false
    }
    
    func openAddService(for projectId: String) {
        selectedProjectId = projectId
        showingAddService = true
    }
    
    func closeAddService() {
        showingAddService = false
        selectedProjectId = nil
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
                await loadProjects()
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
