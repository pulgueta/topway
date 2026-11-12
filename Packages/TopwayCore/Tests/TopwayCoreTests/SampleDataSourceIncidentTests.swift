import Testing

@testable import TopwayCore

struct SampleDataSourceIncidentTests {
    @Test("The sample incident is open, and its text says that it is a sample")
    func sampleIncident() async throws {
        let incident = try #require(await SampleDataSource().fetchOpenIncident())

        #expect(incident.isOpen)
        #expect(incident.message.hasPrefix("Sample incident"))
        #expect(incident.link.absoluteString == "https://status.railway.com")
    }
}
