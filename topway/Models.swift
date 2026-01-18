import Foundation

// MARK: - GraphQL Response Wrappers

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable, Hashable {
    let message: String
}

// MARK: - Projects Query Response

struct WorkspaceData: Decodable {
    let workspace: Workspace
}

struct Workspace: Decodable {
    let projects: ProjectConnection
}

struct ProjectConnection: Decodable {
    let edges: [ProjectEdge]
}

struct ProjectEdge: Decodable {
    let node: Project
}

// MARK: - Project Model

struct Project: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let services: ServiceConnection
    let environments: EnvironmentConnection
}

// MARK: - Service Models

struct ServiceConnection: Decodable, Hashable {
    let edges: [ServiceEdge]
}

struct ServiceEdge: Decodable, Hashable {
    let node: Service
}

struct Service: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
}

// MARK: - Environment Models

struct EnvironmentConnection: Decodable, Hashable {
    let edges: [EnvironmentEdge]
}

struct EnvironmentEdge: Decodable, Hashable {
    let node: RailwayEnvironment
}

struct RailwayEnvironment: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
}

// MARK: - Service Create Response

struct ServiceCreateData: Decodable {
    let serviceCreate: ServiceCreateResult
}

struct ServiceCreateResult: Decodable {
    let id: String
}

// MARK: - Project Delete Response

struct ProjectDeleteData: Decodable {
    let projectDelete: Bool
}

// MARK: - Variables Response

struct VariablesData: Decodable {
    let variables: [String: String]
}

// MARK: - Variable Upsert Response

struct VariableUpsertData: Decodable {
    let variableUpsert: Bool
}

// MARK: - Variable Delete Response

struct VariableDeleteData: Decodable {
    let variableDelete: Bool
}

// MARK: - Service Delete Response

struct ServiceDeleteData: Decodable {
    let serviceDelete: Bool
}

// MARK: - Deployments Response

struct DeploymentsData: Decodable {
    let deployments: DeploymentConnection
}

struct DeploymentConnection: Decodable {
    let edges: [DeploymentEdge]
}

struct DeploymentEdge: Decodable {
    let node: Deployment
}

struct Deployment: Identifiable, Decodable, Hashable {
    let id: String
    let status: String
    let staticUrl: String?
    let createdAt: String
    
    var statusDisplay: String {
        switch status.lowercased() {
        case "success": return "Running"
        case "building": return "Building"
        case "deploying": return "Deploying"
        case "failed": return "Failed"
        case "crashed": return "Crashed"
        case "removed": return "Removed"
        case "sleeping": return "Sleeping"
        default: return status.capitalized
        }
    }
    
    var statusColor: String {
        switch status.lowercased() {
        case "success": return "green"
        case "building", "deploying": return "yellow"
        case "failed", "crashed": return "red"
        case "removed": return "gray"
        case "sleeping": return "purple"
        default: return "gray"
        }
    }
    
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return createdAt
    }
}

// MARK: - Deployment Restart Response

struct DeploymentRestartData: Decodable {
    let deploymentRestart: Bool
}

// MARK: - Service Redeploy Response

struct ServiceRedeployData: Decodable {
    let serviceInstanceRedeploy: Bool
}

// MARK: - Variable Model (for UI display)

struct EnvironmentVariable: Identifiable, Hashable {
    let id: String
    let name: String
    let value: String
    
    init(name: String, value: String) {
        self.id = name
        self.name = name
        self.value = value
    }
}

// MARK: - Convenience Extensions

extension Project {
    var serviceList: [Service] {
        services.edges.map { $0.node }
    }
    
    var environmentList: [RailwayEnvironment] {
        environments.edges.map { $0.node }
    }
}

extension Workspace {
    var projectList: [Project] {
        projects.edges.map { $0.node }
    }
}
