import Testing
import TopwayCore

struct ReferenceStatusTests {
    let services = [Service(id: "s-api", name: "api"), Service(id: "s-pg", name: "postgres")]
    let variables = ProjectVariables(
        shared: ["LOG_LEVEL": "info"],
        byService: [
            "s-api": ["PORT": "8080", "RAILWAY_PUBLIC_DOMAIN": "api.up.railway.app"],
            "s-pg": ["DATABASE_URL": "postgresql://db"],
        ])

    func status(_ namespace: ReferenceNamespace, _ name: String, from serviceId: String = "s-api")
        -> ReferenceTargetStatus
    {
        variables.status(
            of: ReferenceTarget(namespace: namespace, variableName: name), from: serviceId,
            services: services)
    }

    @Test("A reference to a variable of a service that has it is found")
    func foundInService() {
        #expect(status(.service("postgres"), "DATABASE_URL") == .found)
    }

    @Test("A reference to a service name that the project does not have is a missing service")
    func missingService() {
        #expect(status(.service("billing"), "API_URL") == .missingService)
        // The name must be exact.
        #expect(status(.service("Postgres"), "DATABASE_URL") == .missingService)
    }

    @Test("A reference to a name that the service does not have is a missing variable")
    func missingVariable() {
        #expect(status(.service("postgres"), "PASSWORD") == .missingVariable)
    }

    @Test("A RAILWAY_ name that Railway did not list is set by Railway")
    func setByRailway() {
        #expect(status(.service("postgres"), "RAILWAY_PRIVATE_DOMAIN") == .setByRailway)
        #expect(status(.service("api"), "RAILWAY_PUBLIC_DOMAIN") == .found)
    }

    @Test("Shared references check the shared variables")
    func shared() {
        #expect(status(.shared, "LOG_LEVEL") == .found)
        #expect(status(.shared, "SENTRY_DSN") == .missingVariable)
    }

    @Test("Same-service references check the service that has the reference")
    func sameService() {
        #expect(status(.sameService, "PORT") == .found)
        #expect(status(.sameService, "PORT", from: "s-pg") == .missingVariable)
    }

    @Test("Links give each target one time, with its status")
    func links() {
        let links = ReferenceLink.links(
            in: "${{postgres.DATABASE_URL}}/${{ postgres.DATABASE_URL }}?b=${{ billing.URL }}",
            serviceId: "s-api", services: services, variables: variables)

        #expect(
            links == [
                ReferenceLink(
                    target: ReferenceTarget(
                        namespace: .service("postgres"), variableName: "DATABASE_URL"),
                    status: .found),
                ReferenceLink(
                    target: ReferenceTarget(namespace: .service("billing"), variableName: "URL"),
                    status: .missingService),
            ])
    }

    @Test("With no project variables, each link is not checked")
    func linksNotChecked() {
        let links = ReferenceLink.links(
            in: "${{shared.LOG_LEVEL}}", serviceId: "s-api", services: services, variables: nil)

        #expect(links.map(\.status) == [.notChecked])
    }

    @Test(
        "Each status has a short text",
        arguments: [
            (ReferenceTargetStatus.found, "Found"),
            (.missingService, "Service not found"),
            (.missingVariable, "Variable not found"),
            (.setByRailway, "Set by Railway"),
            (.notChecked, "Not checked"),
        ])
    func labels(status: ReferenceTargetStatus, label: String) {
        #expect(status.label == label)
    }

    @Test("A row names the target, and a same-service target says so")
    func displayNames() {
        #expect(
            ReferenceTarget(namespace: .service("postgres"), variableName: "DATABASE_URL")
                .displayName == "postgres.DATABASE_URL")
        #expect(
            ReferenceTarget(namespace: .shared, variableName: "LOG_LEVEL").displayName
                == "shared.LOG_LEVEL")
        #expect(
            ReferenceTarget(namespace: .sameService, variableName: "PORT").displayName
                == "PORT in this service")
    }

    @Test("VoiceOver reads the target and its status")
    func accessibilityDescription() {
        let link = ReferenceLink(
            target: ReferenceTarget(namespace: .service("billing"), variableName: "API_URL"),
            status: .missingService)

        #expect(link.accessibilityDescription == "Reference to billing.API_URL: Service not found")
    }
}
