/// The sample actions of the Manage menu of one deployment.
extension SampleDataSource {
    /// Starts a new deployment, as Railway does for a rollback. Returns `false` when the
    /// deployment does not exist.
    public func rollbackDeployment(deploymentId: String, token: String) -> Bool {
        guard let key = key(ofDeployment: deploymentId) else { return false }
        startDeployment(key: key)
        return true
    }

    /// Returns `false` when the deployment does not exist or is not in progress.
    public func cancelDeployment(deploymentId: String, token: String) -> Bool {
        setRemoved(deploymentId: deploymentId) { $0.availableActions == [.cancel] }
    }

    /// Returns `false` when the deployment does not exist.
    public func removeDeployment(deploymentId: String, token: String) -> Bool {
        setRemoved(deploymentId: deploymentId) { _ in true }
    }

    // MARK: - Private Methods

    private func key(ofDeployment deploymentId: String) -> String? {
        deployments.first { $0.value.contains { $0.id == deploymentId } }?.key
    }

    /// A rollback is possible only to a removed deployment that ran before.
    private func setRemoved(deploymentId: String, when isPermitted: (Deployment) -> Bool) -> Bool {
        guard let key = key(ofDeployment: deploymentId),
            let index = deployments[key]?.firstIndex(where: { $0.id == deploymentId }),
            let deployment = deployments[key]?[index], isPermitted(deployment)
        else { return false }
        deployments[key]?[index] = Self.changing(
            deployment, to: "REMOVED", canRollback: deployment.status == "SUCCESS")
        return true
    }
}
