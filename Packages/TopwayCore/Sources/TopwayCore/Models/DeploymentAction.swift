/// An action on one deployment that is not always possible. `Deployment.availableActions`
/// gives the actions of a deployment.
public enum DeploymentAction: Sendable {
    /// Deploy this earlier deployment again.
    case rollback
    /// Stop a build or a deploy that is in progress.
    case cancel
    /// Remove the deployment, so the service stops in the environment.
    case remove
}
