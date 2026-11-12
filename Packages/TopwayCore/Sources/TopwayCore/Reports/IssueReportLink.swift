import Foundation

/// Makes the link that opens an issue form on GitHub with the device fields filled in.
///
/// GitHub fills a text field of an issue form from a query item that has the `id` of the field.
/// It does not fill a dropdown, so the device fields in `.github/ISSUE_TEMPLATE` are text fields.
/// Keep the names here the same as the field ids in those forms.
public enum IssueReportLink {
    /// The link has only the form and the details in `DeviceDetails`. A detail with no value
    /// gets no query item, so the user fills that field.
    public static func url(for kind: IssueKind, details: DeviceDetails) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "github.com"
        components.path = "/pulgueta/topway/issues/new"

        let fields = [
            ("template", template(for: kind)),
            ("app-version", versionText(details.appVersion, build: details.appBuild)),
            ("macos-version", macOSText(details)),
            ("mac-model", details.macModel),
            (
                "architecture",
                details.architecture == .appleSilicon ? "Apple silicon (arm64)" : "Intel (x86_64)"
            ),
            ("data-mode", details.isSampleMode ? "Sample data" : "Railway token"),
        ]
        components.queryItems = fields.filter { !$0.1.isEmpty }.map {
            URLQueryItem(name: $0.0, value: $0.1)
        }
        // `URLComponents` does not encode "+", and GitHub reads "+" in a query as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        return components.url
    }

    private static func template(for kind: IssueKind) -> String {
        switch kind {
        case .bug: "bug_report.yml"
        case .crash: "crash_report.yml"
        }
    }

    private static func macOSText(_ details: DeviceDetails) -> String {
        guard !details.macOSVersion.isEmpty else { return "" }
        return versionText("macOS \(details.macOSVersion)", build: details.macOSBuild)
    }

    /// For example "1.0 (1)", or "1.0" when there is no build.
    private static func versionText(_ version: String, build: String) -> String {
        build.isEmpty ? version : "\(version) (\(build))"
    }
}
