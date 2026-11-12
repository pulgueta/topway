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

    @Test("The service name is the text before the last dot")
    func serviceName() {
        let targets = VariableReference.all(in: "${{ backend-api.PORT }} ${{web.v2.URL}}")
            .map(\.target)

        #expect(
            targets == [
                ReferenceTarget(namespace: .service("backend-api"), variableName: "PORT"),
                ReferenceTarget(namespace: .service("web.v2"), variableName: "URL"),
            ])
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
