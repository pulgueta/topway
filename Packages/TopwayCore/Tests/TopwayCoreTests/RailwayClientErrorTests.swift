import Foundation
import Testing
import TopwayCore

struct RailwayClientErrorTests {
    private func failingCall(_ reply: StubReply) async -> RailwayError? {
        let client = RailwayClient(session: StubServer(reply).session)
        return await #expect(throws: RailwayError.self) {
            _ = try await client.deleteProject(projectId: "p1", token: "secret")
        }
    }

    @Test("A 401 response is an unauthorized error")
    func unauthorized() async throws {
        let error = try #require(await failingCall(StubReply(status: 401, body: "<html>")))

        guard case .unauthorized = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
    }

    // Railway answers a request that has a bad token with status 200 and this message.
    @Test(
        "A Not Authorized GraphQL error is the same error as a 401 response",
        arguments: [
            #"{"errors":[{"message":"Not Authorized"}]}"#,
            #"{"errors":[{"message":"not authorized"}],"data":null}"#,
            #"{"errors":[{"message":"Other"},{"message":"Not Authorized"}]}"#,
        ])
    func notAuthorizedMessage(body: String) async throws {
        let error = try #require(await failingCall(StubReply(body: body)))

        guard case .unauthorized = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
    }

    @Test("A Workspace not found GraphQL error does not mean that Railway rejected the token")
    func workspaceNotFoundMessage() async throws {
        let body = #"{"errors":[{"message":"Workspace not found"}]}"#
        let error = try #require(await failingCall(StubReply(body: body)))

        guard case .graphQLError(let message) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(message == "Workspace not found")
        #expect(!error.isTokenRejected)
    }

    @Test("A 429 response gives the Retry-After value")
    func rateLimitedWithRetryAfter() async throws {
        let error = try #require(
            await failingCall(
                StubReply(status: 429, headers: ["Retry-After": "30"], body: "<html>")))

        guard case .rateLimited(let retryAfter) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(retryAfter == "30")
    }

    @Test("A 429 response without Retry-After gives no value")
    func rateLimitedWithoutRetryAfter() async throws {
        let error = try #require(await failingCall(StubReply(status: 429, body: "<html>")))

        guard case .rateLimited(let retryAfter) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(retryAfter == nil)
    }

    @Test(
        "Other non-2xx responses give the status, and no message without a GraphQL error",
        arguments: [
            (403, "forbidden"),
            (404, "<html>"),
            (500, #"{"data":{"projectDelete":true}}"#),
            (500, "Internal Server Error"),
            (503, ""),
            (400, #"{"errors":[]}"#),
        ])
    func otherStatuses(status: Int, body: String) async throws {
        let error = try #require(await failingCall(StubReply(status: status, body: body)))

        guard case .httpStatus(let code, let message) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(code == status)
        #expect(message == nil)
    }

    @Test("A non-2xx response with GraphQL errors keeps the status and the first message")
    func statusWithGraphQLMessage() async throws {
        let body = #"{"errors":[{"message":"Name is not valid"},{"message":"Second"}]}"#
        let error = try #require(await failingCall(StubReply(status: 400, body: body)))

        guard case .httpStatus(let code, let message) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(code == 400)
        #expect(message == "Name is not valid")
    }

    @Test(
        "A 401 or 429 response stays the same when the body has a GraphQL error",
        arguments: [401, 429])
    func authAndRateLimitIgnoreBody(status: Int) async throws {
        let body = #"{"errors":[{"message":"Details"}]}"#
        let error = try #require(await failingCall(StubReply(status: status, body: body)))

        switch (status, error) {
        case (401, .unauthorized), (429, .rateLimited(retryAfter: nil)):
            break
        default:
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("A GraphQL errors array is an error")
    func graphQLErrors() async throws {
        let error = try #require(
            await failingCall(
                StubReply(body: #"{"errors":[{"message":"Not found"},{"message":"Denied"}]}"#)))

        guard case .graphQLError(let message) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(message == "Not found, Denied")
    }

    @Test("A GraphQL error wins when the data has an unusable shape")
    func graphQLErrorWithPartialData() async throws {
        let error = try #require(
            await failingCall(
                StubReply(body: #"{"data":{"projectDelete":null},"errors":[{"message":"Denied"}]}"#)
            ))

        guard case .graphQLError(let message) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(message == "Denied")
    }

    @Test("Each HTTP error has a message for the user")
    func errorMessages() {
        #expect(RailwayError.unauthorized.errorDescription == "Railway did not accept your token.")
        #expect(
            RailwayError.rateLimited(retryAfter: "30").errorDescription
                == "Railway got too many requests. Try again in 30 seconds.")
        #expect(
            RailwayError.rateLimited(retryAfter: nil).errorDescription
                == "Railway got too many requests. Try again later.")
        #expect(
            RailwayError.httpStatus(500, message: nil).errorDescription
                == "Railway sent an error. Status code: 500.")
        #expect(
            RailwayError.httpStatus(400, message: "Name is not valid").errorDescription
                == "Railway sent an error. Status code: 400. Details: Name is not valid")
    }
}
