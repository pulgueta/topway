import Foundation
import Testing

@testable import TopwayCore

struct ReferenceDataTests {
    @Test("Variables come unrendered, so a reference keeps its template")
    func unrenderedVariables() async throws {
        let server = StubServer(
            StubReply(
                body: #"{"data":{"variables":{"DATABASE_URL":"${{ postgres.DATABASE_URL }}"}}}"#))

        let variables = try await RailwayClient(session: server.session).fetchVariables(
            projectId: "p1", environmentId: "e1", serviceId: "s1", token: "secret")

        #expect(variables == ["DATABASE_URL": "${{ postgres.DATABASE_URL }}"])
        let query = try #require(server.requests.first?.query)
        #expect(query.contains("unrendered: true"))
    }

    @Test("A sealed variable has the value null, so it decodes with its name and no value")
    func sealedVariable() async throws {
        let server = StubServer(
            StubReply(body: #"{"data":{"variables":{"PORT":"8080","STRIPE_KEY":null}}}"#))

        let variables = try await RailwayClient(session: server.session).fetchVariables(
            projectId: "p1", environmentId: "e1", serviceId: "s1", token: "secret")

        #expect(variables == ["PORT": "8080", "STRIPE_KEY": String?.none])
        #expect(variables.keys.contains("STRIPE_KEY"))
    }

    @Test("Project variables read the shared variables and each service in one request")
    func projectVariables() async throws {
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"shared":{"LOG_LEVEL":"info"},"s0":{"PORT":"8080"},
                     "s1":{"API_URL":"${{shared.HOST}}","SECRET":null}}}
                    """))

        let variables = try await RailwayClient(session: server.session).fetchProjectVariables(
            projectId: "p1", environmentId: "e1", serviceIds: ["web", "api"], token: "secret")

        // A sealed variable has no value in the answer. Its name is still a target.
        #expect(
            variables
                == ProjectVariables(
                    shared: ["LOG_LEVEL": "info"],
                    byService: [
                        "web": ["PORT": "8080"],
                        "api": ["API_URL": "${{shared.HOST}}", "SECRET": ""],
                    ]))
        #expect(server.requests.count == 1)
        let request = try #require(server.requests.first)
        #expect(
            request.variables == [
                "projectId": "p1", "environmentId": "e1", "s0": "web", "s1": "api",
            ])
        let query = try #require(request.query)
        #expect(query.components(separatedBy: "unrendered: true").count == 4)
    }

    @Test("Project variables of an environment with no services read only the shared variables")
    func projectVariablesWithNoServices() async throws {
        let server = StubServer(StubReply(body: #"{"data":{"shared":{}}}"#))

        let variables = try await RailwayClient(session: server.session).fetchProjectVariables(
            projectId: "p1", environmentId: "e1", serviceIds: [], token: "secret")

        #expect(variables == ProjectVariables(shared: [:], byService: [:]))
        #expect(server.requests.first?.variables == ["projectId": "p1", "environmentId": "e1"])
    }

    @Test("Sample project variables give the shared variables and the requested services")
    func sampleProjectVariables() async {
        let source = SampleDataSource()

        let variables = await source.fetchProjectVariables(
            projectId: "storefront", environmentId: "storefront-production",
            serviceIds: ["storefront-api", "storefront-postgres"], token: "")

        #expect(variables.shared == ["LOG_LEVEL": "info"])
        #expect(Set(variables.byService.keys) == ["storefront-api", "storefront-postgres"])
        #expect(
            variables.byService["storefront-api"]?["DATABASE_URL"] == "${{ postgres.DATABASE_URL }}"
        )
    }

    @Test("Sample data has a reference to a service that the project does not have")
    func sampleMissingTarget() async throws {
        let source = SampleDataSource()
        let project = try #require(
            await source.fetchProjects(workspaceId: "", token: "").first { $0.id == "storefront" })
        let services = project.serviceList
        let variables = await source.fetchProjectVariables(
            projectId: "storefront", environmentId: "storefront-production",
            serviceIds: services.map(\.id), token: "")

        let statuses = (variables.byService["storefront-worker"] ?? [:]).values.flatMap {
            ReferenceLink.links(
                in: $0, serviceId: "storefront-worker", services: services, variables: variables
            ).map(\.status)
        }

        #expect(statuses.contains(.missingService))
        #expect(statuses.contains(.found))
    }

    @Test("A project gives the services that are in an environment")
    func servicesInEnvironment() {
        let project = Project(
            id: "p1", name: "shop",
            services: ServiceConnection(edges: [
                ServiceEdge(node: Service(id: "s1", name: "web")),
                ServiceEdge(node: Service(id: "s2", name: "api")),
                ServiceEdge(node: Service(id: "s3", name: "old")),
            ]),
            environments: EnvironmentConnection(edges: [
                EnvironmentEdge(
                    node: RailwayEnvironment(
                        id: "e1", name: "production",
                        instances: [
                            ServiceInstance(serviceId: "s2", latestDeployment: nil),
                            ServiceInstance(serviceId: "s1", latestDeployment: nil),
                            ServiceInstance(
                                serviceId: "s3", latestDeployment: nil,
                                deletedAt: "2026-11-01T00:00:00Z"),
                        ]))
            ]))

        #expect(project.serviceList(in: "e1").map(\.name) == ["web", "api"])
        #expect(project.serviceList(in: "e9").isEmpty)
    }
}
