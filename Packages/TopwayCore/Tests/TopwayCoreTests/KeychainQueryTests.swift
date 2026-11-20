import Security
import Testing

@testable import TopwayCore

/// On macOS, a query with no `kSecUseDataProtectionKeychain` value goes to both keychains
/// (`SecItemCategorizeQuery` in Apple's Security source). Thus each query must name its keychain.
struct KeychainQueryTests {
    private let flag = kSecUseDataProtectionKeychain as String

    @Test("A query of the file-based keychain does not go to the data protection keychain")
    func fileBasedQuery() {
        let query = Keychain(service: "com.example", usesDataProtectionKeychain: false)
            .query(for: "railwayOAuth")

        #expect(query[flag] as? Bool == false)
    }

    @Test("A query of the data protection keychain goes only to the data protection keychain")
    func dataProtectionQuery() {
        let query = Keychain(service: "com.example", usesDataProtectionKeychain: true)
            .query(for: "railwayOAuth")

        #expect(query[flag] as? Bool == true)
    }
}
