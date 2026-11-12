import Testing
import TopwayCore

struct EnvironmentSelectionTests {
    @Test("An available selection stays")
    func keeps() {
        #expect(EnvironmentSelection.reconciled("e2", available: ["e1", "e2"]) == "e2")
    }

    @Test("A deleted selection changes to the first available environment")
    func deleted() {
        #expect(EnvironmentSelection.reconciled("e2", available: ["e1", "e3"]) == "e1")
    }

    @Test("With no environments, there is no selection")
    func noEnvironments() {
        #expect(EnvironmentSelection.reconciled("e2", available: []) == nil)
    }

    @Test("With no selection, the first new environment is selected")
    func firstEnvironment() {
        #expect(EnvironmentSelection.reconciled(nil, available: ["e1"]) == "e1")
    }
}
