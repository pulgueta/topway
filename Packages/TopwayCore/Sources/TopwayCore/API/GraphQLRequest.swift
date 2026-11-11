struct GraphQLRequest: Encodable, Equatable {
    let query: String
    let variables: [String: String]
}
