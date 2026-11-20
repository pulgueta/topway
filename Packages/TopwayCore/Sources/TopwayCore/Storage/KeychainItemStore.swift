/// One keychain that keeps secret strings by account. The one-time move in
/// `KeychainMigration` uses two: the file-based keychain and the data protection keychain.
protocol KeychainItemStore {
    /// Returns the secret for `account`, or `nil` when it is absent or the keychain refuses
    /// the read.
    func read(_ account: String) -> String?

    /// Stores the secret for `account`, or replaces it.
    /// - Returns: `false` when the keychain refuses the write.
    func save(_ value: String, for account: String) -> Bool

    /// Deletes the secret for `account`.
    /// - Returns: `true` also when nothing was stored.
    func delete(_ account: String) -> Bool
}
