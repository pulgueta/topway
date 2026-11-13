extension RailwayClient {
    /// The signed-in user and the workspaces that the user shared with Topway. The query has
    /// no variables.
    public func fetchAccount(token: String) async throws -> RailwayAccount {
        let query = """
            query Account {
              me {
                name
                email
                workspaces {
                  id
                  name
                }
              }
            }
            """

        let data: AccountData = try await execute(query: query, variables: [:], token: token)
        return data.me
    }
}
