@testable import TopwayCore

/// A keychain in memory. It records the reads and the deletes, and it can refuse a save or a
/// delete, as a real keychain can.
final class FakeKeychain: KeychainItemStore {
    var items: [String: String]
    var refusesSave = false
    /// A file-based item that another code signature made refuses a delete.
    var refusesDelete = false
    private(set) var reads: [String] = []
    private(set) var deletes: [String] = []

    init(_ items: [String: String] = [:]) {
        self.items = items
    }

    func read(_ account: String) -> String? {
        reads.append(account)
        return items[account]
    }

    func save(_ value: String, for account: String) -> Bool {
        guard !refusesSave else { return false }
        items[account] = value
        return true
    }

    func delete(_ account: String) -> Bool {
        deletes.append(account)
        guard !refusesDelete else { return false }
        items[account] = nil
        return true
    }
}
