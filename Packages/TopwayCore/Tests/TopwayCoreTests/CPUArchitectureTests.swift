import Testing
import TopwayCore

struct CPUArchitectureTests {
    @Test(
        "The architecture comes from the hardware values of sysctl",
        arguments: [
            // Apple silicon, native code: Rosetta does not run the app.
            (1, 0, CPUArchitecture.appleSilicon),
            // Apple silicon, Intel code: Rosetta runs the app.
            (1, 1, CPUArchitecture.appleSiliconWithRosetta),
            // Only Rosetta runs on Apple silicon, so a translated app is on Apple silicon.
            (nil, 1, CPUArchitecture.appleSiliconWithRosetta),
            // An Intel Mac does not have `sysctl.proc_translated`.
            (0, nil, CPUArchitecture.intel),
            (nil, nil, CPUArchitecture.intel),
        ] as [(Int?, Int?, CPUArchitecture)])
    func architecture(arm64: Int?, translated: Int?, expected: CPUArchitecture) {
        #expect(CPUArchitecture(arm64: arm64, translated: translated) == expected)
    }
}
