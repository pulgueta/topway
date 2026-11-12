/// The processor type of the Mac.
public enum CPUArchitecture: Sendable, Equatable {
    case appleSilicon
    /// An Apple silicon Mac that runs the Intel code of Topway with Rosetta.
    case appleSiliconWithRosetta
    case intel

    /// Reads the hardware, not the code of the app, so an Intel build that runs with Rosetta
    /// gives an Apple silicon Mac.
    /// - Parameters:
    ///   - arm64: The value of `hw.optional.arm64`, or `nil` when the system does not give it.
    ///   - translated: The value of `sysctl.proc_translated`, or `nil` when the system does
    ///     not give it. It is 1 when Rosetta runs the app.
    public init(arm64: Int?, translated: Int?) {
        if translated == 1 {
            self = .appleSiliconWithRosetta
        } else if arm64 == 1 {
            self = .appleSilicon
        } else {
            self = .intel
        }
    }
}
