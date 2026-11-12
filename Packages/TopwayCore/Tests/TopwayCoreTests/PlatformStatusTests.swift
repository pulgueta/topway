import Foundation
import Testing

@testable import TopwayCore

struct PlatformStatusTests {
    /// The answer of `https://backboard.railway.com/graphql/v2` with no token, recorded
    /// 2026-11-12. Railway reported a planned maintenance and no incident.
    private let recordedNoIncident = """
        {"data":{"platformStatus":{"isStable":false,"incident":null,"maintenance":{"id":"WLG0R306",\
        "message":"API and Dashboard Maintenance","start":"2026-11-15T08:00:00.000Z",\
        "status":"NOTSTARTEDYET","url":"https://status.railway.com"}}}}
        """

    /// No incident was open on 2026-11-12, so this answer is not recorded. Its fields and
    /// status values are those of the `Incident` type and the `IncidentStatus` enum of the
    /// Railway schema. The id and the message are those of a past incident.
    private func answer(status: String, url: String = "https://status.railway.com") -> String {
        """
        {"data":{"platformStatus":{"isStable":false,"incident":{"id":"97GIDVEY",\
        "message":"GitHub Outage Affecting Builds","status":"\(status)","url":"\(url)",\
        "createdAt":"2026-11-08T10:11:06.997Z"},"maintenance":null}}}
        """
    }

    private func openIncident(in json: String) throws -> PlatformIncident? {
        try JSONDecoder().decode(GraphQLResponse<PlatformStatusData>.self, from: Data(json.utf8))
            .data?.platformStatus.openIncident
    }

    @Test("A recorded answer with a maintenance and no incident gives no open incident")
    func recordedAnswer() throws {
        #expect(try openIncident(in: recordedNoIncident) == nil)
    }

    @Test(
        "An incident that Railway works on is open",
        arguments: [
            ("INVESTIGATING", "Investigating"), ("IDENTIFIED", "Identified"),
            ("MONITORING", "Monitoring"), ("SOMETHING_NEW", "Something New"),
        ])
    func open(status: String, display: String) throws {
        let incident = try #require(try openIncident(in: answer(status: status)))

        #expect(incident.id == "97GIDVEY")
        #expect(incident.message == "GitHub Outage Affecting Builds")
        #expect(incident.isOpen)
        #expect(incident.statusDisplay == display)
    }

    @Test("A resolved incident is not open", arguments: ["RESOLVED", "resolved"])
    func resolved(status: String) throws {
        #expect(try openIncident(in: answer(status: status)) == nil)
    }

    @Test(
        "Only an HTTPS page on railway.com opens. Other links give the status page",
        arguments: [
            (
                "https://status.railway.com/incident/97GIDVEY",
                "https://status.railway.com/incident/97GIDVEY"
            ),
            ("https://railway.com/status", "https://railway.com/status"),
            ("http://status.railway.com/incident/1", "https://status.railway.com"),
            ("https://railway.com.example.org/x", "https://status.railway.com"),
            ("https://notrailway.com/x", "https://status.railway.com"),
            ("file:///etc/hosts", "https://status.railway.com"),
            ("", "https://status.railway.com"),
        ])
    func link(url: String, opened: String) {
        let incident = PlatformIncident(id: "1", message: "m", status: "MONITORING", url: url)

        #expect(incident.link.absoluteString == opened)
    }

    @Test(
        "A check is due with no earlier check, and 5 minutes after the last check",
        arguments: [(nil, true), (0.0, false), (299.0, false), (300.0, true), (4_000.0, true)]
            as [(TimeInterval?, Bool)])
    func checkIsDue(age: TimeInterval?, isDue: Bool) {
        let now = Date(timeIntervalSince1970: 1_794_312_000)

        #expect(IncidentCheck.isDue(lastCheck: age.map { now - $0 }, now: now) == isDue)
    }
}
