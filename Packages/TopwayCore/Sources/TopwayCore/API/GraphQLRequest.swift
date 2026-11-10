struct GraphQLRequest: Encodable {
    let query: String
    let variables: [String: String]
}
