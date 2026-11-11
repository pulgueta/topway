/// What `GraphQLWebSocket` must do after a message from the server.
enum SubscriptionStep<Payload> {
    /// The server accepted the connection. Send the message and tell the consumer.
    case connected(send: GraphQLClientMessage)
    /// Send the message, for example a pong.
    case reply(GraphQLClientMessage)
    /// Give the payload to the consumer.
    case payload(Payload)
    /// The server ended the subscription.
    case completed
    case ignore
}

extension SubscriptionStep: Equatable where Payload: Equatable {}
