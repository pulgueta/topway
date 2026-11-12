import Foundation
import Testing
import TopwayCore

struct IssueReportLinkTests {
    private let details = DeviceDetails(
        appVersion: "1.0",
        appBuild: "1",
        macOSVersion: "26.2",
        macOSBuild: "25C56",
        macModel: "Mac16,1",
        architecture: .appleSilicon,
        isSampleMode: false,
        hasToken: true)

    private func queryItems(_ kind: IssueKind, _ details: DeviceDetails) throws -> [String: String]
    {
        let url = try #require(IssueReportLink.url(for: kind, details: details))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = components.queryItems ?? []
        // A field that shows two times in the link is an error.
        #expect(Set(items.map(\.name)).count == items.count)
        return Dictionary(items.map { ($0.name, $0.value ?? "") }) { first, _ in first }
    }

    @Test("The link opens the new issue page of the Topway repository")
    func newIssuePage() throws {
        let url = try #require(IssueReportLink.url(for: .bug, details: details))

        #expect(url.scheme == "https")
        #expect(url.host() == "github.com")
        #expect(url.path() == "/pulgueta/topway/issues/new")
    }

    @Test(
        "Each kind of report selects its issue form",
        arguments: [
            (IssueKind.bug, "bug_report.yml"),
            (IssueKind.crash, "crash_report.yml"),
        ])
    func template(kind: IssueKind, file: String) throws {
        #expect(try queryItems(kind, details)["template"] == file)
    }

    @Test(
        "The link fills the device fields of the form by their field ids",
        arguments: IssueKind.allCases)
    func deviceFields(kind: IssueKind) throws {
        let items = try queryItems(kind, details)

        #expect(items["app-version"] == "1.0 (1)")
        #expect(items["macos-version"] == "macOS 26.2 (25C56)")
        #expect(items["mac-model"] == "Mac16,1")
        #expect(items["architecture"] == "Apple silicon (arm64)")
        #expect(items["data-mode"] == "Railway token")
    }

    @Test(
        "The link has only the form and the device fields, so it has no token and no Workspace ID")
    func onlyDeviceFields() throws {
        let names = Set(try queryItems(.crash, details).keys)

        #expect(
            names == [
                "template", "app-version", "macos-version", "mac-model", "architecture",
                "data-mode",
            ])
    }

    @Test("An Intel Mac in sample mode gives the Intel and the sample data values")
    func intelAndSampleMode() throws {
        var details = details
        details.architecture = .intel
        details.isSampleMode = true

        let items = try queryItems(.bug, details)

        #expect(items["architecture"] == "Intel (x86_64)")
        #expect(items["data-mode"] == "Sample data")
    }

    @Test("With no token and no sample data, the data field says that there is no token")
    func noToken() throws {
        var details = details
        details.hasToken = false

        #expect(try queryItems(.bug, details)["data-mode"] == "No token")
    }

    @Test("Sample mode gives the sample data value also when a token is saved")
    func sampleModeWithToken() throws {
        var details = details
        details.isSampleMode = true

        #expect(try queryItems(.crash, details)["data-mode"] == "Sample data")
    }

    @Test(
        "The link percent-encodes spaces, parentheses are safe, and a plus sign stays a plus sign")
    func encoding() throws {
        var details = details
        details.appVersion = "1.0+beta & more"

        let url = try #require(IssueReportLink.url(for: .bug, details: details))
        let link = url.absoluteString

        // GitHub reads "+" in a query as a space, so a real plus sign must be "%2B".
        #expect(link.contains("app-version=1.0%2Bbeta%20%26%20more%20(1)"))
        #expect(link.contains("macos-version=macOS%2026.2%20(25C56)"))
        #expect(!link.contains("+"))
        #expect(try queryItems(.bug, details)["app-version"] == "1.0+beta & more (1)")
    }

    @Test("A detail that the Mac does not give leaves its field empty for the user")
    func missingDetails() throws {
        var details = details
        details.macModel = ""
        details.macOSBuild = ""
        details.appBuild = ""

        let items = try queryItems(.crash, details)

        #expect(items["mac-model"] == nil)
        #expect(items["macos-version"] == "macOS 26.2")
        #expect(items["app-version"] == "1.0")
    }
}
