struct VariablesData: Decodable {
    /// A sealed variable has the value `null`.
    let variables: [String: String?]
}
