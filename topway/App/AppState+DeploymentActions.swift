import TopwayCore

/// The actions of the Manage menu of one deployment.
extension AppState {
    func perform(_ action: DeploymentAction, deploymentId: String) async -> Bool {
        switch action {
        case .rollback:
            await runAction(failure: "Railway did not start the rollback. Try again.") {
                try await $0.rollbackDeployment(deploymentId: deploymentId, token: $1)
            }
        case .cancel:
            await runAction(failure: "Railway did not cancel the deployment. Try again.") {
                try await $0.cancelDeployment(deploymentId: deploymentId, token: $1)
            }
        case .remove:
            await runAction(failure: "Railway did not remove the deployment. Try again.") {
                try await $0.removeDeployment(deploymentId: deploymentId, token: $1)
            }
        }
    }
}
