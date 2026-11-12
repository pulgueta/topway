/// What Topway knows about a database after Railway accepted its deploy.
public enum DatabaseDeployResult: Sendable {
    /// Railway made the database.
    case complete
    /// Railway accepted the deploy, but Topway did not see its end. The database can show
    /// later. This is not a failure, so the user must not add the database again.
    case pending
}
