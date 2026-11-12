import Foundation
import TopwayCore

extension DeviceDetails {
    /// The details of this app and this Mac. Topway reads them only when the user reports a problem.
    static func current(isSampleMode: Bool) -> DeviceDetails {
        let info = Bundle.main.infoDictionary
        let system = ProcessInfo.processInfo.operatingSystemVersion
        #if arch(arm64)
            let architecture = CPUArchitecture.appleSilicon
        #else
            let architecture = CPUArchitecture.intel
        #endif

        return DeviceDetails(
            appVersion: info?["CFBundleShortVersionString"] as? String ?? "",
            appBuild: info?["CFBundleVersion"] as? String ?? "",
            macOSVersion: "\(system.majorVersion).\(system.minorVersion)"
                + (system.patchVersion > 0 ? ".\(system.patchVersion)" : ""),
            macOSBuild: systemText("kern.osversion"),
            macModel: systemText("hw.model"),
            architecture: architecture,
            isSampleMode: isSampleMode)
    }

    /// A text value from `sysctl`, or an empty text when the system does not give it.
    private static func systemText(_ name: String) -> String {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return "" }
        var bytes = [UInt8](repeating: 0, count: size)
        guard sysctlbyname(name, &bytes, &size, nil, 0) == 0 else { return "" }
        return String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
}
