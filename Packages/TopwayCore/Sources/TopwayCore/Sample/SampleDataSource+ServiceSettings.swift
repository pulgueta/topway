/// The sample settings of a service.
extension SampleDataSource {
    /// Throws when the service does not exist.
    public func fetchServiceSettings(environmentId: String, serviceId: String, token: String)
        throws -> ServiceSettings
    {
        let service = try service(withId: serviceId)
        let key = Self.key(environmentId, serviceId)
        if let saved = settings[key] {
            // The name can be newer than the saved settings of this environment.
            var current = saved
            current.name = service.name
            return current
        }
        return Self.seedSettings(for: service)
    }

    /// Throws when the service does not exist.
    public func updateServiceSettings(
        _ changes: ServiceSettingsChanges, environmentId: String, serviceId: String, token: String
    ) throws -> Bool {
        var current = try fetchServiceSettings(
            environmentId: environmentId, serviceId: serviceId, token: token)
        for (setting, value) in changes.instance {
            current[setting] = value
        }
        settings[Self.key(environmentId, serviceId)] = current
        if let name = changes.name {
            rename(serviceId: serviceId, to: name)
        }
        return true
    }

    // MARK: - Private Methods

    private func service(withId serviceId: String) throws -> Service {
        guard let service = projects.flatMap(\.serviceList).first(where: { $0.id == serviceId })
        else { throw RailwayError.graphQLError("Service not found.") }
        return service
    }

    private func rename(serviceId: String, to name: String) {
        guard
            let index = projects.firstIndex(where: {
                $0.serviceList.contains { $0.id == serviceId }
            })
        else { return }
        replaceServices(
            inProjectAt: index,
            with: projects[index].serviceList.map {
                $0.id == serviceId ? Service(id: $0.id, name: name) : $0
            })
    }

    /// A database is an image with no commands. Other services are a sample repository.
    /// The ID gives the kind, because the user can change the name.
    private static func seedSettings(for service: Service) -> ServiceSettings {
        if service.id.hasSuffix("-postgres") {
            return ServiceSettings(
                name: service.name, source: "ghcr.io/railwayapp-templates/postgres-ssl:18")
        }
        if service.id.hasSuffix("-redis") {
            return ServiceSettings(name: service.name, source: "redis:8.2")
        }
        return ServiceSettings(
            name: service.name, source: "sample/\(service.id)",
            values: [
                .buildCommand: "npm run build", .startCommand: "npm run start",
                .healthcheckPath: "/health",
            ])
    }
}
