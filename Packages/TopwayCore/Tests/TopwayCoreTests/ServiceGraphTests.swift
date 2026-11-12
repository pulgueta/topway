import Testing
import TopwayCore

struct ServiceGraphTests {
    let services = [
        Service(id: "s-web", name: "web"), Service(id: "s-api", name: "api"),
        Service(id: "s-pg", name: "postgres"), Service(id: "s-worker", name: "worker"),
    ]

    func graph(shared: [String: String] = [:], _ byService: [String: [String: String]])
        -> ServiceGraph
    {
        ServiceGraph(
            services: services, variables: ProjectVariables(shared: shared, byService: byService))
    }

    @Test("Many references from one service to another give one link with each variable name")
    func noDuplicates() {
        let graph = graph([
            "s-api": [
                "DATABASE_URL": "${{ postgres.DATABASE_URL }}",
                "PG": "${{postgres.PGUSER}}:${{postgres.PGPASSWORD}}",
            ]
        ])

        #expect(
            graph.edges == [
                ServiceGraphEdge(
                    from: .service(id: "s-api"), to: .service(id: "s-pg"),
                    variableNames: ["DATABASE_URL", "PG"])
            ])
    }

    @Test("Two services can link to each other")
    func cycle() {
        let graph = graph([
            "s-web": ["API_URL": "https://${{ api.RAILWAY_PUBLIC_DOMAIN }}"],
            "s-api": ["CORS_ORIGIN": "https://${{ web.RAILWAY_PUBLIC_DOMAIN }}"],
        ])

        #expect(
            graph.edges == [
                ServiceGraphEdge(
                    from: .service(id: "s-web"), to: .service(id: "s-api"),
                    variableNames: ["API_URL"]),
                ServiceGraphEdge(
                    from: .service(id: "s-api"), to: .service(id: "s-web"),
                    variableNames: ["CORS_ORIGIN"]),
            ])
    }

    @Test("A name that no service has gives a link to a missing service")
    func missingService() {
        let graph = graph(["s-worker": ["BILLING_URL": "${{ billing.API_URL }}"]])

        #expect(
            graph.edges == [
                ServiceGraphEdge(
                    from: .service(id: "s-worker"), to: .missingService(name: "billing"),
                    variableNames: ["BILLING_URL"])
            ])
    }

    @Test("Shared variables are a node when a link uses them")
    func shared() {
        let graph = graph(
            shared: ["DB": "${{ postgres.DATABASE_URL }}", "LOG_LEVEL": "info"],
            ["s-api": ["LOG_LEVEL": "${{ shared.LOG_LEVEL }}"]])

        #expect(
            graph.edges == [
                ServiceGraphEdge(
                    from: .service(id: "s-api"), to: .shared, variableNames: ["LOG_LEVEL"]),
                ServiceGraphEdge(
                    from: .shared, to: .service(id: "s-pg"), variableNames: ["DB"]),
            ])
        #expect(
            graph.nodes == [
                .service(id: "s-web"), .service(id: "s-api"), .service(id: "s-pg"),
                .service(id: "s-worker"), .shared,
            ])
        #expect(graph.sentence(for: graph.edges[1]) == "The shared variables use postgres in DB.")
    }

    @Test("References to the same service give no link")
    func sameService() {
        let graph = graph([
            "s-api": ["URL": "http://${{ HOST }}:${{PORT}}", "SELF": "${{ api.PORT }}"]
        ])

        #expect(graph.edges.isEmpty)
        #expect(!graph.nodes.contains(.shared))
    }

    @Test("A node gives the links that start and end at it")
    func usesAndUsedBy() {
        let graph = graph([
            "s-web": ["API_URL": "${{ api.URL }}"],
            "s-worker": ["API_URL": "${{ api.URL }}", "DB": "${{ postgres.DATABASE_URL }}"],
        ])

        #expect(
            graph.uses(.service(id: "s-worker")).map(\.to) == [
                .service(id: "s-api"), .service(id: "s-pg"),
            ])
        #expect(
            graph.usedBy(.service(id: "s-api")).map(\.from) == [
                .service(id: "s-web"), .service(id: "s-worker"),
            ])
        #expect(graph.uses(.service(id: "s-pg")).isEmpty)
    }

    @Test("Names and sentences use the names of the services")
    func wording() {
        let graph = graph([
            "s-api": ["DB": "${{postgres.DATABASE_URL}}", "PG": "${{ postgres.PGUSER }}"],
            "s-worker": ["BILLING_URL": "${{ billing.API_URL }}", "LOG": "${{ shared.LOG }}"],
        ])

        #expect(graph.name(of: .service(id: "s-pg")) == "postgres")
        #expect(graph.name(of: .shared) == "Shared variables")
        #expect(graph.name(of: .missingService(name: "billing")) == "billing")
        #expect(
            graph.edges.map(graph.sentence(for:)) == [
                "api uses postgres in DB, PG.",
                "worker uses billing in BILLING_URL. The project has no service with this name.",
                "worker uses the shared variables in LOG.",
            ])
    }

    @Test("The sample project has links, a shared link and a link to a missing service")
    func sample() async throws {
        let source = SampleDataSource()
        let project = try #require(
            await source.fetchProjects(workspaceId: "", token: "").first { $0.id == "storefront" })
        let services = project.serviceList(in: "storefront-production")
        let variables = await source.fetchProjectVariables(
            projectId: project.id, environmentId: "storefront-production",
            serviceIds: services.map(\.id), token: "")

        let graph = ServiceGraph(services: services, variables: variables)

        #expect(graph.nodes.contains(.shared))
        #expect(
            graph.uses(.service(id: "storefront-worker")).map(\.to).contains(
                .missingService(name: "billing")))
        #expect(graph.usedBy(.service(id: "storefront-postgres")).count == 2)
    }
}
