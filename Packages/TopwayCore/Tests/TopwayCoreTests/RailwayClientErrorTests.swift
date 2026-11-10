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
        "Other non-2xx responses give the status and do not decode the body",
        arguments: [
            (400, #"{"errors":[{"message":"bad"}]}"#),
            (403, "forbidden"),
            (404, "<html>"),
            (500, #"{"data":{"projectDelete":true}}"#),
            (503, ""),
        ])
    func otherStatuses(status: Int, body: String) async throws {
        let error = try #require(await failingCall(StubReply(status: status, body: body)))

        guard case .httpStatus(let code) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(code == status)
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
            RailwayError.httpStatus(500).errorDescription
                == "Railway sent an error. Status code: 500.")
    }
}
