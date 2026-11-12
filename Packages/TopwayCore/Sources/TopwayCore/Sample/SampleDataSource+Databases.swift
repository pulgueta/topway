/// The sample database templates.
extension SampleDataSource {
    /// Adds a service with the name of the database, a running deployment in the
    /// environment, and sample connection variables. Throws when the project or the
    /// environment does not exist. The sample database is complete at once, so it has no
    /// workflow.
    public func deployDatabase(
        _ template: DatabaseTemplate, projectId: String, environmentId: String, token: String
    ) throws -> String? {
        guard let project = projects.first(where: { $0.id == projectId }),
            project.environmentList.contains(where: { $0.id == environmentId })
        else { throw RailwayError.graphQLError("Project or environment not found.") }

        let seed = Self.seedDatabase(template)
        // A second database of the same kind gets a number, so each name is different.
        let sameKind = project.serviceList.filter { $0.name.hasPrefix(seed.name) }.count
        let name = sameKind == 0 ? seed.name : "\(seed.name)-\(sameKind + 1)"
        let serviceId = try addService(named: name, toProject: projectId)
        let key = Self.key(environmentId, serviceId)
        variables[key] = seed.variables
        settings[key] = ServiceSettings(name: name, source: seed.image)
        startDeployment(key: key)
        return nil
    }

    /// The sample data has no workflow, so each database is complete.
    public nonisolated func waitForDatabase(workflowId: String, token: String)
        -> DatabaseDeployResult
    {
        .complete
    }

    private static func seedDatabase(_ template: DatabaseTemplate)
        -> (name: String, image: String, variables: [String: String])
    {
        switch template {
        case .postgres:
            (
                "Postgres", "ghcr.io/railwayapp-templates/postgres-ssl:18",
                [
                    "DATABASE_URL":
                        "postgresql://postgres:sample-password@postgres.railway.internal:5432/railway",
                    "PGPORT": "5432",
                ]
            )
        case .mysql:
            (
                "MySQL", "mysql:8",
                [
                    "MYSQL_URL": "mysql://root:sample-password@mysql.railway.internal:3306/railway",
                    "MYSQLPORT": "3306",
                ]
            )
        case .redis:
            (
                "Redis", "redis:8.2",
                [
                    "REDIS_URL": "redis://default:sample-password@redis.railway.internal:6379",
                    "REDISPORT": "6379",
                ]
            )
        case .mongo:
            (
                "MongoDB", "mongo:8.0",
                [
                    "MONGO_URL": "mongodb://mongo:sample-password@mongodb.railway.internal:27017",
                    "MONGOPORT": "27017",
                ]
            )
        }
    }
}
