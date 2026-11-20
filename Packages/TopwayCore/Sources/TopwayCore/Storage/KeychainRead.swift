/// The result of a read of one keychain item.
enum KeychainRead {
    case found(String)
    /// The keychain has no item for the account.
    case notFound
    /// The keychain did not give the item, for example because it is locked or the user
    /// denied the access. The item can be there, so this is not the same as `notFound`.
    case refused
}
