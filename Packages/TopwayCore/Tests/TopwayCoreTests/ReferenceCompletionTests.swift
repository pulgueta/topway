import Testing
import TopwayCore

struct ReferenceCompletionTests {
    let services = [
        Service(id: "s-api", name: "api"), Service(id: "s-pg", name: "postgres"),
        Service(id: "s-redis", name: "redis"), Service(id: "s-web", name: "web"),
    ]
    let variables = ProjectVariables(
        shared: ["LOG_LEVEL": "info"],
        byService: [
            "s-api": ["PORT": "8080", "DATABASE_URL": "${{postgres.DATABASE_URL}}"],
            "s-pg": ["PGUSER": "postgres", "DATABASE_URL": "postgresql://db"],
            "s-redis": [:],
        ])
    let targets = [
        ReferenceTarget(namespace: .shared, variableName: "LOG_LEVEL"),
        ReferenceTarget(namespace: .service("postgres"), variableName: "DATABASE_URL"),
        ReferenceTarget(namespace: .service("postgres"), variableName: "PGUSER"),
        ReferenceTarget(namespace: .sameService, variableName: "PORT"),
    ]

    @Test("The menu gives the same service, the shared variables, then the other services")
    func groups() {
        let groups = variables.referenceGroups(
            for: "s-api", services: services, excluding: "DATABASE_URL")

        #expect(
            groups == [
                ReferenceGroup(namespace: .sameService, variableNames: ["PORT"]),
                ReferenceGroup(namespace: .shared, variableNames: ["LOG_LEVEL"]),
                ReferenceGroup(
                    namespace: .service("postgres"), variableNames: ["DATABASE_URL", "PGUSER"]),
            ])
        #expect(groups.map(\.title) == ["This service", "Shared variables", "postgres"])
        #expect(
            groups.last?.targets == [
                ReferenceTarget(namespace: .service("postgres"), variableName: "DATABASE_URL"),
                ReferenceTarget(namespace: .service("postgres"), variableName: "PGUSER"),
            ])
    }

    @Test("The text after an open reference before the cursor is the query")
    func query() {
        let text = "url=${{ post"

        let completion = ReferenceCompletion(text: text, cursor: text.endIndex)

        #expect(completion?.query == "post")
        #expect(
            completion?.matches(in: targets).map(\.expression) == [
                "postgres.DATABASE_URL", "postgres.PGUSER",
            ])
    }

    @Test("An empty query gives the first targets")
    func emptyQuery() {
        let text = "${{"

        let matches = ReferenceCompletion(text: text, cursor: text.endIndex)?
            .matches(in: targets, limit: 2)

        #expect(matches?.map(\.expression) == ["shared.LOG_LEVEL", "postgres.DATABASE_URL"])
    }

    @Test("The match does not use uppercase and lowercase letters")
    func caseInsensitive() {
        let text = "${{ pguser"

        let matches = ReferenceCompletion(text: text, cursor: text.endIndex)?.matches(in: targets)

        #expect(matches?.map(\.expression) == ["postgres.PGUSER"])
    }

    @Test(
        "There is no completion when the cursor is not in an open reference",
        arguments: ["no reference", "${{ api.URL }} and more", "${{ api\nnext line", "${{ a } b"])
    func noCompletion(text: String) {
        #expect(ReferenceCompletion(text: text, cursor: text.endIndex) == nil)
    }

    @Test("A selected target completes the reference and closes the braces")
    func insertCloses() throws {
        let text = "url=${{ post"
        let completion = try #require(ReferenceCompletion(text: text, cursor: text.endIndex))

        let result = completion.insert(targets[1], into: text)

        #expect(result.text == "url=${{postgres.DATABASE_URL}}")
        #expect(result.cursor == result.text.endIndex)
    }

    @Test("A close just after the cursor is not added again")
    func insertBeforeClose() throws {
        let text = "${{ po}}/path"
        let cursor = try #require(text.range(of: "}}")).lowerBound
        let completion = try #require(ReferenceCompletion(text: text, cursor: cursor))

        let result = completion.insert(targets[1], into: text)

        #expect(result.text == "${{postgres.DATABASE_URL}}/path")
        #expect(String(result.text[..<result.cursor]) == "${{postgres.DATABASE_URL}}")
    }

    /// Gives the result of a completion at the `|` of `marked`.
    func complete(_ marked: String, with target: ReferenceTarget) throws -> (
        text: String, beforeCursor: String
    ) {
        let cursorOffset = try #require(marked.firstIndex(of: "|")).utf16Offset(in: marked)
        let text = marked.replacingOccurrences(of: "|", with: "")
        let cursor = String.Index(utf16Offset: cursorOffset, in: text)
        let completion = try #require(ReferenceCompletion(text: text, cursor: cursor))
        let result = completion.insert(target, into: text)
        return (result.text, String(result.text[..<result.cursor]))
    }

    @Test("In a reference with spaces before its close, the completion replaces the close too")
    func insertBeforeSpacedClose() throws {
        let result = try complete("${{ po| }}/path", with: targets[1])

        #expect(result.text == "${{postgres.DATABASE_URL}}/path")
        #expect(result.beforeCursor == "${{postgres.DATABASE_URL}}")
    }

    @Test("In the middle of a reference, the completion replaces the rest of it")
    func insertInsideReference() throws {
        let result = try complete("a ${{po|stgres.OLD}} b", with: targets[1])

        #expect(result.text == "a ${{postgres.DATABASE_URL}} b")
        #expect(result.beforeCursor == "a ${{postgres.DATABASE_URL}}")
    }

    @Test("An open reference at the end gets its close")
    func insertAtEnd() throws {
        let result = try complete("url=${{ po|", with: targets[1])

        #expect(result.text == "url=${{postgres.DATABASE_URL}}")
        #expect(result.beforeCursor == result.text)
    }

    @Test(
        "An open reference in the middle keeps the text and the references after it",
        arguments: [
            "a ${{ po| rest", "a ${{ po| and ${{api.URL}} rest", "a ${{ po|\nrest}}",
        ])
    func insertInMiddle(marked: String) throws {
        let result = try complete(marked, with: targets[1])
        let rest = String(marked[marked.index(after: try #require(marked.firstIndex(of: "|")))...])

        #expect(result.beforeCursor == "a ${{postgres.DATABASE_URL}}")
        #expect(result.text == result.beforeCursor + rest)
    }

    @Test("The menu puts the template in place of the selection, or at the cursor")
    func insertFromMenu() throws {
        let target = ReferenceTarget(namespace: .service("api"), variableName: "HOST")
        let selected = "a XX b"
        let range = try #require(selected.range(of: "XX"))

        let replaced = target.insert(into: selected, replacing: range)
        let appended = target.insert(
            into: "https://", replacing: "https://".endIndex..<"https://".endIndex)

        #expect(replaced.text == "a ${{api.HOST}} b")
        #expect(String(replaced.text[..<replaced.cursor]) == "a ${{api.HOST}}")
        #expect(appended.text == "https://${{api.HOST}}")
        #expect(appended.cursor == appended.text.endIndex)
    }
}
