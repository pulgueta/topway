import Foundation

/// A message that the app sends over the `graphql-transport-ws` protocol.
enum GraphQLClientMessage: Encodable, Equatable {
    case connectionInit
    case subscribe(id: String, GraphQLRequest)
    case complete(id: String)
    case pong

    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case payload
    }

    /// The JSON text of the message, with sorted keys.
    var text: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        // The message has only strings, so the encoding cannot fail.
        let data = (try? encoder.encode(self)) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .connectionInit:
            try container.encode("connection_init", forKey: .type)
        case .subscribe(let id, let request):
            try container.encode("subscribe", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(request, forKey: .payload)
        case .complete(let id):
            try container.encode("complete", forKey: .type)
            try container.encode(id, forKey: .id)
        case .pong:
            try container.encode("pong", forKey: .type)
        }
    }
}
