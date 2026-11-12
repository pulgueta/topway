import Foundation
import Testing

@testable import TopwayCore

struct DatabaseTemplateTests {
    /// The codes that the `template(code:)` query of Railway answered on 2026-11-12, and
    /// that the Railway CLI uses for `railway add --database`.
    @Test("The four databases have the template codes of Railway")
    func codes() {
        #expect(
            DatabaseTemplate.allCases.map(\.rawValue) == ["postgres", "mysql", "redis", "mongo"])
        #expect(
            DatabaseTemplate.allCases.map(\.title) == ["PostgreSQL", "MySQL", "Redis", "MongoDB"])
    }

    private func decode(_ json: String) throws -> JSONValue {
        try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
    }

    @Test("Each variable gets its default as its value, and all other fields stay")
    func filled() throws {
        let config = try decode(
            """
            {"services":{"s1":{"name":"Postgres","haTemplateCode":"postgres-ha",
              "volumeMounts":{"s1":{"mountPath":"/data"}},
              "variables":{
                "PGPORT":{"defaultValue":"5432","isOptional":false,"description":"Port"},
                "POSTGRES_PASSWORD":{"defaultValue":"${{ secret(32) }}"},
                "EXTRA":{"isOptional":true},
                "EMPTY":{"defaultValue":"","isOptional":true},
                "REMOVED":null}}}}
            """)

        let expected = try decode(
            """
            {"services":{"s1":{"name":"Postgres","haTemplateCode":"postgres-ha",
              "volumeMounts":{"s1":{"mountPath":"/data"}},
              "variables":{
                "PGPORT":{"defaultValue":"5432","isOptional":false,"description":"Port",
                  "value":"5432"},
                "POSTGRES_PASSWORD":{"defaultValue":"${{ secret(32) }}",
                  "value":"${{ secret(32) }}"},
                "EXTRA":{"isOptional":true},
                "EMPTY":{"defaultValue":"","isOptional":true},
                "REMOVED":null}}}}
            """)
        #expect(try TemplateConfig.filled(config) == expected)
    }

    @Test("A variable that needs a value from the user stops the deploy")
    func missingVariable() throws {
        let config = try decode(
            #"{"services":{"s1":{"variables":{"API_KEY":{"description":"Your key"}}}}}"#)

        #expect(throws: TemplateConfigProblem.missingVariable("API_KEY")) {
            try TemplateConfig.filled(config)
        }
    }

    @Test("A service with no variables stays unchanged")
    func noVariables() throws {
        let config = try decode(#"{"services":{"s1":{"name":"Redis"}}}"#)

        #expect(try TemplateConfig.filled(config) == config)
    }

    @Test(
        "The workflow status says when to stop",
        arguments: [
            ("Complete", nil, WorkflowStep.done),
            ("Running", nil, .wait),
            ("NotFound", nil, .wait),
            ("NewStatus", nil, .wait),
            ("Error", "volume failed", .failed("volume failed")),
            ("Error", nil, .failed("Railway did not add the database.")),
        ])
    func workflowStep(status: String, error: String?, step: WorkflowStep) {
        #expect(WorkflowResult(status: status, error: error).step == step)
    }
}
