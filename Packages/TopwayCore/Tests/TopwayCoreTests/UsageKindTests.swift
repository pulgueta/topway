import Testing

@testable import TopwayCore

struct UsageKindTests {
    @Test("Each resource has a title")
    func titles() {
        #expect(UsageKind.allCases.map(\.title) == ["CPU", "Memory", "Network egress", "Volumes"])
    }

    @Test(
        "Railway gives minutes. Topway shows hours, and GB for the network",
        arguments: [
            (UsageKind.cpu, 1_230.0, "20.5 vCPU-hours"), (.memory, 30_720, "512.0 GB-hours"),
            (.egress, 1.254, "1.25 GB"), (.volume, 600, "10.0 GB-hours"),
            (.cpu, 0, "0.0 vCPU-hours"),
        ])
    func formatted(kind: UsageKind, value: Double, text: String) {
        #expect(kind.formatted(value) == text)
    }
}
