/// An event of a GraphQL subscription stream.
enum SubscriptionEvent<Payload: Sendable>: Sendable {
    /// Railway accepted the connection.
    case connected
    case payload(Payload)
}

extension SubscriptionEvent: Equatable where Payload: Equatable {}
