/// A message that Railway sends over the `graphql-transport-ws` protocol.
enum GraphQLServerMessage<Payload: Decodable>: Decodable {
    case connectionAck
    case next(id: String, GraphQLResponse<Payload>)
    case error(id: String, [GraphQLError])
    case complete(id: String)
    case ping
    case pong

    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "connection_ack":
            self = .connectionAck
        case "next":
            self = .next(
                id: try container.decode(String.self, forKey: .id),
                try container.decode(GraphQLResponse<Payload>.self, forKey: .payload))
        case "error":
            self = .error(
                id: try container.decode(String.self, forKey: .id),
                try container.decode([GraphQLError].self, forKey: .payload))
        case "complete":
            self = .complete(id: try container.decode(String.self, forKey: .id))
        case "ping":
            self = .ping
        case "pong":
            self = .pong
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown message type: \(type)")
        }
    }
}

extension GraphQLServerMessage: Equatable where Payload: Equatable {}
