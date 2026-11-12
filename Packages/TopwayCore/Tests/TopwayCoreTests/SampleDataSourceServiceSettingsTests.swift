import Foundation
import Testing

@testable import TopwayCore

struct SampleDataSourceServiceSettingsTests {
    private let ids = ("storefront-production", "storefront-web")

    @Test("A sample service has a name, a source and settings")
    func fetch() async throws {
        let source = SampleDataSource()

        let web = try await source.fetchServiceSettings(
            environmentId: ids.0, serviceId: ids.1, token: "")
        let postgres = try await source.fetchServiceSettings(
            environmentId: ids.0, serviceId: "storefront-postgres", token: "")

        #expect(web.name == "web")
        #expect(web.source == "sample/storefront-web")
        #expect(web[.startCommand] == "npm run start")
        #expect(web[.healthcheckPath] == "/health")
        #expect(postgres.source == "ghcr.io/railwayapp-templates/postgres-ssl:18")
        #expect(postgres[.startCommand] == "")
    }

    @Test("A save changes the settings of one environment, and the name in the projects")
    func update() async throws {
        let source = SampleDataSource()
        let changes = ServiceSettingsChanges(
            name: "shop", instance: [.startCommand: "node server.js", .healthcheckPath: ""])

        let didSave = try await source.updateServiceSettings(
            changes, environmentId: ids.0, serviceId: ids.1, token: "")

        #expect(didSave)
        let production = try await source.fetchServiceSettings(
            environmentId: ids.0, serviceId: ids.1, token: "")
        let staging = try await source.fetchServiceSettings(
            environmentId: "storefront-staging", serviceId: ids.1, token: "")
        #expect(production.name == "shop")
        #expect(production[.startCommand] == "node server.js")
        #expect(production[.healthcheckPath] == "")
        #expect(staging.name == "shop")
        #expect(staging[.startCommand] == "npm run start")
        #expect(staging.source == "sample/storefront-web")
        let projects = await source.fetchProjects(workspaceId: "", token: "")
        #expect(projects.first?.serviceList.first?.name == "shop")
    }

    @Test("A service that does not exist gives an error, not empty settings")
    func missingService() async {
        let source = SampleDataSource()

        await #expect(throws: RailwayError.self) {
            try await source.fetchServiceSettings(
                environmentId: "storefront-production", serviceId: "missing", token: "")
        }
        await #expect(throws: RailwayError.self) {
            try await source.updateServiceSettings(
                ServiceSettingsChanges(name: "x"), environmentId: "storefront-production",
                serviceId: "missing", token: "")
        }
    }
}
