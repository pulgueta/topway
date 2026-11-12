import Testing

@testable import TopwayCore

struct MetricKindTests {
    @Test("Each metric has a title")
    func titles() {
        #expect(
            MetricKind.allCases.map(\.title) == ["CPU", "Memory", "Network in", "Network out"])
    }

    @Test(
        "CPU values show as vCPU",
        arguments: [
            (0, "0 vCPU"), (0.004, "< 0.01 vCPU"), (0.256, "0.26 vCPU"), (1, "1.0 vCPU"),
            (12.34, "12.3 vCPU"),
        ])
    func cpu(value: Double, text: String) {
        #expect(MetricKind.cpu.formatted(value) == text)
    }

    @Test(
        "Sizes below 1 GB show as MB, and larger sizes show as GB",
        arguments: [
            (0, "0 MB"), (0.0005, "0.5 MB"), (0.005, "5.1 MB"), (0.5, "512 MB"),
            (1, "1.00 GB"), (2.345, "2.35 GB"), (12.34, "12.3 GB"),
        ])
    func size(value: Double, text: String) {
        #expect(MetricKind.memory.formatted(value) == text)
        #expect(MetricKind.networkIn.formatted(value) == text)
        #expect(MetricKind.networkOut.formatted(value) == text)
    }

    @Test(
        "A size that is not zero and is below 0.1 MB does not show as zero",
        arguments: [(0.00001, "< 0.1 MB"), (0.00009, "< 0.1 MB"), (0.0001, "0.1 MB")])
    func smallSize(value: Double, text: String) {
        #expect(MetricKind.memory.formatted(value) == text)
        #expect(MetricKind.networkIn.formatted(value) == text)
        #expect(MetricKind.networkOut.formatted(value) == text)
    }
}
