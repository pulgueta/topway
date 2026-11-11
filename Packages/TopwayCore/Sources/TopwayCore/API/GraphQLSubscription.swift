import Foundation

/// The rules of one `graphql-transport-ws` subscription. It has no network code.
///
/// The client sends `connection_init` first. After `connection_ack`, it sends `subscribe`.
/// Railway reads the token from the `Authorization` header of the upgrade request.
struct GraphQLSubscription<Payload: Decodable> {
    static var subprotocol: String { "graphql-transport-ws" }

    let id: String
    let request: GraphQLRequest
    private var isAcknowledged = false

    init(id: String, request: GraphQLRequest) {
        self.id = id
        self.request = request
    }

    mutating func receive(_ text: String) throws(RailwayError) -> SubscriptionStep<Payload> {
        let message: GraphQLServerMessage<Payload>
        do {
            message = try JSONDecoder().decode(
                GraphQLServerMessage<Payload>.self, from: Data(text.utf8))
        } catch {
            throw .decodingError(error)
        }

        switch message {
        case .connectionAck:
            isAcknowledged = true
            return .connected(send: .subscribe(id: id, request))
        case .ping:
            return .reply(.pong)
        case .pong:
            return .ignore
        case .next(let messageId, _), .error(let messageId, _), .complete(let messageId):
            // The server must not send operation messages before it accepts the connection.
            guard isAcknowledged else { throw .unknown }
            guard messageId == id else { return .ignore }
        }

        switch message {
        case .next(_, let response):
            if let errors = response.errors, !errors.isEmpty {
                throw RailwayError(graphQLErrors: errors)
            }
            guard let data = response.data else { throw .unknown }
            return .payload(data)
        case .error(_, let errors):
            throw RailwayError(graphQLErrors: errors)
        default:
            return .completed
        }
    }

    /// Gives the error for a failed socket. A refused upgrade (HTTP 401) and the close codes
    /// 4401 and 4403 mean that Railway did not accept the token.
    static func error(for failure: any Error, closeCode: Int, httpStatus: Int?) -> RailwayError {
        if let failure = failure as? RailwayError {
            return failure
        }
        if httpStatus == 401 || closeCode == 4401 || closeCode == 4403 {
            return .unauthorized
        }
        return RailwayError(transportFailure: failure)
    }
}
