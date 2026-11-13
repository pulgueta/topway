import Foundation
import Testing
import TopwayCore

struct RailwayAccountTests {
    @Test("The account query reads the name, the email and the shared workspaces")
    func fetchAccount() async throws {
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"me":{"name":"Jane","email":"jane@example.com","workspaces":[
                      {"id":"w1","name":"Personal"},{"id":"w2","name":"ACME"}]}}}
                    """))

        let account = try await RailwayClient(session: server.session)
            .fetchAccount(token: "secret")

        #expect(account.name == "Jane")
        #expect(account.email == "jane@example.com")
        #expect(
            account.workspaces == [
                WorkspaceSummary(id: "w1", name: "Personal"),
                WorkspaceSummary(id: "w2", name: "ACME"),
            ])
        let request = try #require(server.requests.first)
        #expect(request.authorization == "Bearer secret")
        let query = try #require(request.query)
        #expect(query.contains("me"))
        #expect(query.contains("workspaces"))
    }

    @Test("An account with no name decodes")
    func noName() async throws {
        let server = StubServer(
            StubReply(body: #"{"data":{"me":{"name":null,"email":"a@b.c","workspaces":[]}}}"#))

        let account = try await RailwayClient(session: server.session)
            .fetchAccount(token: "secret")

        #expect(account.name == nil)
        #expect(account.workspaces.isEmpty)
    }

    @Test("The saved workspace stays when the account still has it")
    func savedWorkspace() {
        let workspaces = [
            WorkspaceSummary(id: "w1", name: "Personal"), WorkspaceSummary(id: "w2", name: "ACME"),
        ]

        #expect(WorkspaceChoice.selection(saved: "w2", in: workspaces) == "w2")
    }

    @Test("With one workspace, Topway uses it")
    func oneWorkspace() {
        let workspaces = [WorkspaceSummary(id: "w1", name: "Personal")]

        #expect(WorkspaceChoice.selection(saved: "", in: workspaces) == "w1")
        #expect(WorkspaceChoice.selection(saved: "gone", in: workspaces) == "w1")
    }

    @Test("With several workspaces and no saved one, the user chooses")
    func severalWorkspaces() {
        let workspaces = [
            WorkspaceSummary(id: "w1", name: "Personal"), WorkspaceSummary(id: "w2", name: "ACME"),
        ]

        #expect(WorkspaceChoice.selection(saved: "", in: workspaces) == nil)
        #expect(WorkspaceChoice.selection(saved: "gone", in: workspaces) == nil)
    }

    @Test("With no workspaces, there is nothing to use")
    func noWorkspaces() {
        #expect(WorkspaceChoice.selection(saved: "w1", in: []) == nil)
    }
}
