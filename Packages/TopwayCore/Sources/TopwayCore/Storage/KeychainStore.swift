import Foundation

/// Keeps small secret strings in the data protection keychain.
///
/// The items belong to the access group of the app ID (the team ID and the bundle ID), so the
/// App Store build and the Developer ID build share them. They use
/// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, so a secret never leaves this Mac, and
/// Topway can read it only while the Mac is unlocked.
public enum KeychainStore {
    /// Service identifier shared by all of this app's Keychain items.
    private static let service = Bundle.main.bundleIdentifier ?? "com.pulgueta.topway"
    private static let dataProtection = Keychain(
        service: service, usesDataProtectionKeychain: true)
    /// Earlier builds kept their items here.
    private static let fileBased = Keychain(service: service, usesDataProtectionKeychain: false)

    /// Stores (or replaces) the secret for `account`. An empty string deletes it.
    @discardableResult
    public static func save(_ value: String, for account: String) -> Bool {
        guard !value.isEmpty else { return delete(account) }
        return dataProtection.save(value, for: account)
    }

    /// Returns the secret for `account`, or `nil` if absent.
    public static func read(_ account: String) -> String? {
        dataProtection.read(account)
    }

    /// Deletes the secret for `account`. Succeeds even if nothing was stored.
    ///
    /// It also tries to delete the item of an earlier build from the file-based keychain. Only
    /// the signature that made that item can delete it, so the result comes only from the
    /// data protection keychain.
    @discardableResult
    public static func delete(_ account: String) -> Bool {
        _ = fileBased.delete(account)
        return dataProtection.delete(account)
    }

    /// Moves the secret for `account` from the file-based keychain of earlier builds to the
    /// data protection keychain. See `KeychainMigration`.
    /// - Parameter isDone: The marker that the last call gave.
    /// - Returns: `true` when the move is complete. Keep it and give it to the next call, so
    ///   Topway never reads the file-based item again.
    public static func moveFileBasedItem(_ account: String, isDone: Bool) -> Bool {
        KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)
            .move(account, isDone: isDone)
    }
}
