/// The details of the app and the Mac that a problem report shows.
///
/// It has no token, no Workspace ID and no project data.
public struct DeviceDetails: Sendable, Equatable {
    /// The app version, for example "1.0".
    public var appVersion: String
    /// The app build, for example "1".
    public var appBuild: String
    /// The macOS version, for example "26.2".
    public var macOSVersion: String
    /// The macOS build, for example "25C56".
    public var macOSBuild: String
    /// The model identifier, for example "Mac16,1".
    public var macModel: String
    public var architecture: CPUArchitecture
    /// `true` when Topway shows sample data and does not connect to Railway.
    public var isSampleMode: Bool

    public init(
        appVersion: String,
        appBuild: String,
        macOSVersion: String,
        macOSBuild: String,
        macModel: String,
        architecture: CPUArchitecture,
        isSampleMode: Bool
    ) {
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.macOSVersion = macOSVersion
        self.macOSBuild = macOSBuild
        self.macModel = macModel
        self.architecture = architecture
        self.isSampleMode = isSampleMode
    }
}
