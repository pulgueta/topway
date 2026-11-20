import Testing

@testable import TopwayCore

struct KeychainMigrationTests {
    private let account = "railwayOAuth"

    @Test("The move copies the file-based item to the data protection keychain, then deletes it")
    func movesItem() {
        let fileBased = FakeKeychain([account: "earlier"])
        let dataProtection = FakeKeychain()

        let isDone = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)
            .move(account, isDone: false)

        #expect(isDone)
        #expect(dataProtection.items == [account: "earlier"])
        #expect(fileBased.items.isEmpty)
    }

    @Test("A move that is done reads no keychain and changes nothing")
    func doneMoveDoesNothing() {
        let fileBased = FakeKeychain([account: "earlier"])
        let dataProtection = FakeKeychain()

        let isDone = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)
            .move(account, isDone: true)

        #expect(isDone)
        #expect(fileBased.reads.isEmpty)
        #expect(dataProtection.reads.isEmpty)
        #expect(fileBased.items == [account: "earlier"])
        #expect(dataProtection.items.isEmpty)
    }

    @Test(
        "When the data protection keychain refuses the item, the move is not done and the item stays"
    )
    func refusedSaveKeepsItem() {
        let fileBased = FakeKeychain([account: "earlier"])
        let dataProtection = FakeKeychain()
        dataProtection.refusesSave = true

        let isDone = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)
            .move(account, isDone: false)

        #expect(!isDone)
        #expect(fileBased.items == [account: "earlier"])
        #expect(fileBased.deletes.isEmpty)
    }

    @Test("An item in the data protection keychain stays, and the file-based item is deleted")
    func keepsNewerItem() {
        let fileBased = FakeKeychain([account: "earlier"])
        let dataProtection = FakeKeychain([account: "current"])

        let isDone = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)
            .move(account, isDone: false)

        #expect(isDone)
        #expect(dataProtection.items == [account: "current"])
        #expect(fileBased.items.isEmpty)
    }

    @Test(
        "A file-based item of another signature, which Topway cannot delete, does not stop the move",
        arguments: [nil, "current"])
    func undeletableItem(current: String?) {
        let fileBased = FakeKeychain([account: "earlier"])
        fileBased.refusesDelete = true
        let dataProtection = FakeKeychain()
        dataProtection.items[account] = current

        let isDone = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)
            .move(account, isDone: false)

        #expect(isDone)
        #expect(dataProtection.items == [account: current ?? "earlier"])
    }

    @Test("With no item in either keychain, the move is done")
    func nothingToMove() {
        let fileBased = FakeKeychain()
        let dataProtection = FakeKeychain()

        let isDone = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)
            .move(account, isDone: false)

        #expect(isDone)
        #expect(dataProtection.items.isEmpty)
    }

    @Test("After a sign-out, the next launch does not bring back a file-based item that stays")
    func signOutStaysAfterMove() {
        let fileBased = FakeKeychain([account: "earlier"])
        fileBased.refusesDelete = true
        let dataProtection = FakeKeychain()
        let migration = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)

        let isDone = migration.move(account, isDone: false)
        dataProtection.items[account] = nil
        let isDoneAgain = migration.move(account, isDone: isDone)

        #expect(isDoneAgain)
        #expect(dataProtection.items.isEmpty)
        #expect(fileBased.reads.count == 1)
    }
}
