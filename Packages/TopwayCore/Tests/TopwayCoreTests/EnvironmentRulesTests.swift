import Foundation
import Testing
import TopwayCore

struct EnvironmentRulesTests {
    private let existing = ["production", "staging"]

    @Test("A new name is permitted")
    func newName() {
        #expect(EnvironmentRules.problem(name: "preview", existingNames: existing) == nil)
    }

    @Test("An empty name is not permitted, and it shows no message", arguments: ["", "   ", "\t"])
    func empty(name: String) {
        let problem = EnvironmentRules.problem(name: name, existingNames: existing)

        #expect(problem == .empty)
        #expect(problem?.message == nil)
    }

    @Test(
        "A name that the project has is not permitted, with any letter case and spaces around it",
        arguments: ["staging", "Staging", " PRODUCTION "])
    func duplicate(name: String) {
        let problem = EnvironmentRules.problem(name: name, existingNames: existing)

        #expect(problem == .duplicate)
        #expect(
            problem?.message
                == "This project has an environment with this name. Use a different name.")
    }

    @Test("The clean name has no spaces around it")
    func cleanName() {
        #expect(EnvironmentRules.cleanName("  pr 12 \n") == "pr 12")
    }

    @Test("An empty environment needs no dialog, and a copy of an environment needs one")
    func createHarm() {
        #expect(EnvironmentRules.createHarm(hasSource: false) == .low)
        #expect(EnvironmentRules.createHarm(hasSource: true) == .medium)
    }

    @Test("A project gives no environment that Railway deleted")
    func deletedEnvironments() throws {
        let json = """
            {"id":"p1","name":"shop","services":{"edges":[]},"environments":{"edges":[
              {"node":{"id":"e1","name":"production","deletedAt":null,
                "serviceInstances":{"edges":[]}}},
              {"node":{"id":"e2","name":"pr-12","deletedAt":"2026-11-09T00:00:00Z",
                "serviceInstances":{"edges":[]}}}
            ]}}
            """

        let project = try JSONDecoder().decode(Project.self, from: Data(json.utf8))

        #expect(project.environmentList.map(\.name) == ["production"])
    }
}
