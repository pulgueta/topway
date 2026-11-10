import Testing
import TopwayCore

struct VariableSaveHarmTests {
    private let existingNames: Set<String> = ["API_KEY", "DATABASE_URL"]

    @Test("A new name is low harm")
    func newName() {
        let harm = ConfirmationRules.variableSaveHarm(
            name: "NEW_NAME", isEditing: false, existingNames: existingNames)

        #expect(harm == .low)
    }

    @Test(
        "A name that exists is medium harm, after trimming spaces",
        arguments: ["API_KEY", " API_KEY", "API_KEY  "])
    func existingName(name: String) {
        let harm = ConfirmationRules.variableSaveHarm(
            name: name, isEditing: false, existingNames: existingNames)

        #expect(harm == .medium)
    }

    @Test("Names that differ in case are different names")
    func differentCase() {
        let harm = ConfirmationRules.variableSaveHarm(
            name: "api_key", isEditing: false, existingNames: existingNames)

        #expect(harm == .low)
    }

    @Test("An edit is always medium harm")
    func edit() {
        let harm = ConfirmationRules.variableSaveHarm(
            name: "NEW_NAME", isEditing: true, existingNames: [])

        #expect(harm == .medium)
    }

    @Test("Medium harm applies when the existing names are not known")
    func unknownNames() {
        let harm = ConfirmationRules.variableSaveHarm(
            name: "NEW_NAME", isEditing: false, existingNames: nil)

        #expect(harm == .medium)
    }
}
