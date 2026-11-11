struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?

    private enum CodingKeys: String, CodingKey {
        case data
        case errors
    }

    // Read `errors` first. A response with errors can hold `data` that does not match `T`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let errors = try container.decodeIfPresent([GraphQLError].self, forKey: .errors)
        self.errors = errors
        if let errors, !errors.isEmpty {
            data = nil
        } else {
            data = try container.decodeIfPresent(T.self, forKey: .data)
        }
    }
}

extension GraphQLResponse: Equatable where T: Equatable {}
