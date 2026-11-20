import Foundation
import Security

/// One keychain of this Mac, through the SecItem API. Each item is a generic password of
/// `service`.
struct Keychain: KeychainItemStore {
    let service: String
    /// `true` for the data protection keychain (Apple TN3137). Its items belong to the access
    /// group of the app ID, so each build with the same app ID can read and delete them, and
    /// a build with no signature cannot use it. `false` for the file-based keychain, where
    /// the access list of an item follows the code signature that made it.
    let usesDataProtectionKeychain: Bool

    func read(_ account: String) -> KeychainRead {
        var search = query(for: account)
        search[kSecReturnData as String] = true
        search[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        switch SecItemCopyMatching(search as CFDictionary, &result) {
        case errSecSuccess:
            guard let data = result as? Data, let value = String(data: data, encoding: .utf8)
            else { return .refused }
            return .found(value)
        case errSecItemNotFound:
            return .notFound
        default:
            return .refused
        }
    }

    /// Changes an item in place when it is there, and adds it when it is not. Thus the secret
    /// is always in the keychain, which is not true for a delete and then an add.
    func save(_ value: String, for account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(
            query(for: account) as CFDictionary, attributes as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            let addQuery = query(for: account).merging(attributes) { _, new in new }
            return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
        default:
            return false
        }
    }

    func delete(_ account: String) -> Bool {
        let status = SecItemDelete(query(for: account) as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// With no access group, a query finds the items of all the access groups of the app, and
    /// a new item goes in the default group: the app ID.
    ///
    /// The query always names its keychain. On macOS, a query with no
    /// `kSecUseDataProtectionKeychain` value goes to both keychains, so a delete of the
    /// file-based item would also delete the item in the data protection keychain.
    func query(for account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: usesDataProtectionKeychain,
        ]
    }
}
