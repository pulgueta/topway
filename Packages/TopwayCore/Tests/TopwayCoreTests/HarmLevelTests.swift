import Testing
import TopwayCore

struct HarmLevelTests {
    @Test(
        "Only medium and high harm need a dialog",
        arguments: [
            (HarmLevel.low, false),
            (HarmLevel.medium, true),
            (HarmLevel.high, true),
        ])
    func needsDialog(level: HarmLevel, expected: Bool) {
        #expect(level.needsDialog == expected)
    }

    @Test(
        "Only high harm needs a typed name",
        arguments: [
            (HarmLevel.low, false),
            (HarmLevel.medium, false),
            (HarmLevel.high, true),
        ])
    func needsTypedName(level: HarmLevel, expected: Bool) {
        #expect(level.needsTypedName == expected)
    }

    @Test("High harm allows the action only with the exact name")
    func highHarmConfirmation() {
        #expect(HarmLevel.high.canConfirm(typedText: "api", targetName: "api"))
        #expect(!HarmLevel.high.canConfirm(typedText: "ap", targetName: "api"))
        #expect(!HarmLevel.high.canConfirm(typedText: "", targetName: "api"))
    }

    @Test("Low and medium harm do not read the typed text", arguments: [HarmLevel.low, .medium])
    func otherHarmConfirmation(level: HarmLevel) {
        #expect(level.canConfirm(typedText: "", targetName: "api"))
    }
}
