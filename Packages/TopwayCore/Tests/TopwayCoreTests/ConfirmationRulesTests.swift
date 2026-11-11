import Testing
import TopwayCore

struct ConfirmationRulesTests {
    @Test(
        "Typed text must match the target name exactly",
        arguments: [
            ("api", "api", true),
            ("API", "api", false),
            ("api ", "api", false),
            (" api", "api", false),
            ("", "api", false),
            ("my \"app\"", "my \"app\"", true),
        ])
    func typedTextMatches(typed: String, target: String, expected: Bool) {
        #expect(ConfirmationRules.typedTextMatches(typed, targetName: target) == expected)
    }

    @Test(
        "Only the name production, in any case, is production",
        arguments: [
            ("production", true),
            ("Production", true),
            ("PRODUCTION", true),
            ("staging", false),
            ("production-eu", false),
            ("pre-production", false),
            ("", false),
        ])
    func isProduction(name: String, expected: Bool) {
        #expect(ConfirmationRules.isProduction(environmentName: name) == expected)
    }

    @Test("A project gives the name of its production environment")
    func projectProductionEnvironment() {
        let project = makeProject(environments: ["staging", "Production"])

        #expect(project.productionEnvironmentName == "Production")
    }

    @Test("A project without a production environment gives no name")
    func projectWithoutProductionEnvironment() {
        let project = makeProject(environments: ["staging"])

        #expect(project.productionEnvironmentName == nil)
    }

    private func makeProject(environments: [String]) -> Project {
        Project(
            id: "p1",
            name: "Project",
            services: ServiceConnection(edges: []),
            environments: EnvironmentConnection(
                edges: environments.map {
                    EnvironmentEdge(node: RailwayEnvironment(id: $0, name: $0))
                })
        )
    }
}
