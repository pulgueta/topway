/// Moves a secret one time from the file-based keychain of earlier builds to the data
/// protection keychain.
///
/// In the file-based keychain, the access list of an item follows the code signature that
/// made it. The App Store build and the Developer ID build have different signatures, so the
/// item of the other build can stay after the move. The caller keeps the result as a marker:
/// after a complete move, the rule never reads the file-based keychain again. Thus a sign-out
/// cannot bring back that earlier item at the next launch.
struct KeychainMigration<Store: KeychainItemStore> {
    let fileBased: Store
    let dataProtection: Store

    /// - Parameter isDone: The marker: `true` when an earlier call completed the move.
    /// - Returns: `true` when the move is complete. It is `false` when a keychain refuses a
    ///   read, or the data protection keychain refuses the secret, for example in a build with
    ///   no signature. Then the file-based item stays, and the next call tries again. A
    ///   refused read is not an absent item, so it must not end the move.
    func move(_ account: String, isDone: Bool) -> Bool {
        guard !isDone else { return true }
        switch dataProtection.read(account) {
        case .found:
            break
        case .refused:
            return false
        case .notFound:
            switch fileBased.read(account) {
            case .found(let value):
                guard dataProtection.save(value, for: account) else { return false }
            case .notFound:
                return true
            case .refused:
                return false
            }
        }
        // Only the signature that made the item can delete it, so a failure is not an error.
        _ = fileBased.delete(account)
        return true
    }
}
