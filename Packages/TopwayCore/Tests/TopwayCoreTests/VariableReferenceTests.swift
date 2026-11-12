import Testing
import TopwayCore

struct VariableReferenceTests {
    @Test("Finds service, shared and same-service references, with and without spaces")
    func threeForms() {
        let value = "https://${{ api.RAILWAY_PUBLIC_DOMAIN }}/${{shared.PATH}}?port=${{PORT}}"

        let references = VariableReference.all(in: value)

        #expect(
            references.map(\.target) == [
                ReferenceTarget(namespace: .service("api"), variableName: "RAILWAY_PUBLIC_DOMAIN"),
                ReferenceTarget(namespace: .shared, variableName: "PATH"),
                ReferenceTarget(namespace: .sameService, variableName: "PORT"),
            ])
        #expect(
            references.map { String(value[$0.range]) } == [
                "${{ api.RAILWAY_PUBLIC_DOMAIN }}", "${{shared.PATH}}", "${{PORT}}",
            ])
    }

    @Test("A plain value has no references")
    func plainValue() {
        #expect(VariableReference.all(in: "postgres://user@localhost:5432/db").isEmpty)
    }

    @Test(
        "Text that is not a variable name is not a reference",
        arguments: [
            "${{ secret(32) }}", "${{}}", "${{ . }}", "${{ api. }}", "${{ .VAR }}",
            "${{ api.VAR", "${{ two words }}",
        ])
    func notAReference(value: String) {
        #expect(VariableReference.all(in: value).isEmpty)
    }

    @Test("A service name has letters, digits, underscores and hyphens")
    func serviceName() {
        let targets = VariableReference.all(in: "${{ backend-api.PORT }} ${{my_api2.URL}}")
            .map(\.target)

        #expect(
            targets == [
                ReferenceTarget(namespace: .service("backend-api"), variableName: "PORT"),
                ReferenceTarget(namespace: .service("my_api2"), variableName: "URL"),
            ])
    }

    @Test(
        "A malformed reference gives no link, so no part of the value shows",
        arguments: [
            "${{api.PASSWORD}literal-secret.PORT}}",
            "postgres://${{user:literal-secret@api.HOST}}",
            "${{ api .URL }}",
            "${{api. URL}}",
            "${{my service.URL}}",
            "${{a{literal-secret.URL}}",
            "${{web.v2.URL}}",
            "${{1api.URL}}",
            "${{api.1URL}}",
        ])
    func malformed(value: String) {
        let services = [Service(id: "s-api", name: "api")]
        let variables = ProjectVariables(shared: [:], byService: ["s-api": ["URL": "x"]])

        let links = ReferenceLink.links(
            in: value, serviceId: "s-api", services: services, variables: variables)

        #expect(VariableReference.all(in: value).isEmpty)
        #expect(links.isEmpty)
        #expect(!links.contains { $0.target.displayName.contains("literal-secret") })
    }

    @Test("An opening with no close does not hide a later reference")
    func unclosedOpening() {
        let value = "${{ broken ${{ api.URL }}"

        let references = VariableReference.all(in: value)

        #expect(references.map(\.target.expression) == ["api.URL"])
        #expect(references.map { String(value[$0.range]) } == ["${{ api.URL }}"])
    }

    @Test("A target gives the text between the braces and the template of Railway")
    func targetText() {
        let service = ReferenceTarget(namespace: .service("postgres"), variableName: "DATABASE_URL")
        let shared = ReferenceTarget(namespace: .shared, variableName: "LOG_LEVEL")
        let same = ReferenceTarget(namespace: .sameService, variableName: "PORT")

        #expect(service.template == "${{postgres.DATABASE_URL}}")
        #expect(shared.template == "${{shared.LOG_LEVEL}}")
        #expect(same.template == "${{PORT}}")
    }
}
