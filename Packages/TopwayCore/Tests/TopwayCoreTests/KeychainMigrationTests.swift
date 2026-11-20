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

    @Test("A refused read of the data protection keychain stops the move and changes nothing")
    func refusedDataProtectionRead() {
        let fileBased = FakeKeychain([account: "earlier"])
        let dataProtection = FakeKeychain([account: "current"])
        dataProtection.refusesRead = true

        let isDone = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)
            .move(account, isDone: false)

        #expect(!isDone)
        #expect(dataProtection.items == [account: "current"])
        #expect(fileBased.reads.isEmpty)
        #expect(fileBased.deletes.isEmpty)
    }

    @Test(
        "A refused read of the file-based item does not end the move, so the next launch moves it"
    )
    func refusedFileBasedRead() {
        let fileBased = FakeKeychain([account: "earlier"])
        fileBased.refusesRead = true
        let dataProtection = FakeKeychain()
        let migration = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)

        let isDone = migration.move(account, isDone: false)

        #expect(!isDone)
        #expect(dataProtection.items.isEmpty)
        #expect(fileBased.deletes.isEmpty)

        fileBased.refusesRead = false
        let isDoneAtNextLaunch = migration.move(account, isDone: isDone)

        #expect(isDoneAtNextLaunch)
        #expect(dataProtection.items == [account: "earlier"])
    }

    @Test("After a failed move, a sign-in and a sign-out do not bring back the file-based item")
    func newSignInReplacesFileBasedItem() {
        let fileBased = FakeKeychain([account: "earlier"])
        fileBased.refusesDelete = true
        let dataProtection = FakeKeychain()
        dataProtection.refusesSave = true
        let migration = KeychainMigration(fileBased: fileBased, dataProtection: dataProtection)

        var isDone = migration.move(account, isDone: false)
        // As `AppState` does: a saved sign-in replaces the file-based item, so the move is done.
        dataProtection.refusesSave = false
        if dataProtection.save("new", for: account) {
            isDone = true
        }
        dataProtection.items[account] = nil
        let isDoneAtNextLaunch = migration.move(account, isDone: isDone)

        #expect(isDoneAtNextLaunch)
        #expect(dataProtection.items.isEmpty)
        #expect(fileBased.reads.count == 1)
    }
}
