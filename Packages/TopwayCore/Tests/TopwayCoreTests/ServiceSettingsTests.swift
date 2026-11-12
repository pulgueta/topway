import Foundation
import Testing

@testable import TopwayCore

struct ServiceSettingsTests {
    private let original = ServiceSettings(
        name: "web", source: "acme/web",
        values: [.startCommand: "npm run start", .healthcheckPath: "/health"])

    @Test("Settings that did not change give no changes, also with spaces around a value")
    func noChanges() {
        var edited = original
        edited.name = " web "
        edited[.startCommand] = "npm run start  "
        edited[.buildCommand] = "   "

        #expect(edited.changes(from: original).isEmpty)
    }

    @Test("Only the changed settings are in the changes, with no spaces around them")
    func changedValues() {
        var edited = original
        edited.name = " storefront "
        edited[.startCommand] = " node server.js "
        edited[.rootDirectory] = "/apps/web"

        #expect(
            edited.changes(from: original)
                == ServiceSettingsChanges(
                    name: "storefront",
                    instance: [.startCommand: "node server.js", .rootDirectory: "/apps/web"]))
    }

    @Test("A value that the user removed is an empty text in the changes")
    func removedValue() {
        var edited = original
        edited[.healthcheckPath] = ""

        #expect(
            edited.changes(from: original)
                == ServiceSettingsChanges(instance: [.healthcheckPath: ""]))
    }

    @Test("An empty name stops the save", arguments: ["", "  "])
    func emptyName(name: String) {
        var edited = original
        edited.name = name

        #expect(edited.problem == .emptyName)
        #expect(edited.problem?.message == "Enter a name for the service.")
    }

    @Test(
        "A healthcheck path must start with a slash, or be empty",
        arguments: [
            ("", false), ("/", false), ("/health", false), (" /health ", false), ("health", true),
            ("https://example.com/health", true),
        ])
    func healthcheckPath(path: String, isProblem: Bool) {
        var edited = original
        edited[.healthcheckPath] = path

        #expect((edited.problem == .healthcheckPath) == isProblem)
    }

    @Test("A healthcheck path that Railway has, and that the user did not change, stops no save")
    func unchangedHealthcheckPath() {
        let saved = ServiceSettings(name: "web", values: [.healthcheckPath: "health"])
        var edited = saved
        edited[.startCommand] = "node server.js"

        #expect(edited.problem(comparedTo: saved) == nil)
        edited[.healthcheckPath] = "ready"
        #expect(edited.problem(comparedTo: saved) == .healthcheckPath)
        edited.name = ""
        #expect(edited.problem(comparedTo: saved) == .emptyName)
    }

    @Test("The answer of Railway gives the name, the source and the settings that are set")
    func decoding() throws {
        let json = """
            {"serviceName":"web","source":{"image":null,"repo":"acme/web"},
             "buildCommand":null,"startCommand":"npm run start","rootDirectory":null,
             "healthcheckPath":"/health"}
            """

        let settings = try JSONDecoder().decode(ServiceInstanceSettings.self, from: Data(json.utf8))
            .settings

        #expect(settings == original)
        #expect(settings[.buildCommand] == "")
    }

    @Test("An image is the source when the service has no repository")
    func imageSource() throws {
        let json = #"{"serviceName":"redis","source":{"image":"redis:8.2","repo":null}}"#

        let settings = try JSONDecoder().decode(ServiceInstanceSettings.self, from: Data(json.utf8))
            .settings

        #expect(settings == ServiceSettings(name: "redis", source: "redis:8.2"))
    }
}
