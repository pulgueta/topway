import Foundation
import Testing

@testable import TopwayCore

struct SampleDataSourceDomainTests {
    private let web = ("storefront", "storefront-production", "storefront-web")
    private let api = ("storefront", "storefront-production", "storefront-api")

    private func domains(_ source: SampleDataSource, _ ids: (String, String, String)) async
        -> [Domain]
    {
        await source.fetchDomains(
            projectId: ids.0, environmentId: ids.1, serviceId: ids.2, token: "")
    }

    @Test("The sample web service has a Railway domain and a custom domain that is ready")
    func seed() async {
        let source = SampleDataSource()

        let domains = await domains(source, web)

        #expect(domains.map(\.kind) == [.railway, .custom])
        #expect(
            domains.map(\.name) == ["web-production-sample.up.railway.app", "shop.example.com"])
        #expect(domains.last?.status == .ready)
        #expect(await self.domains(source, api).isEmpty)
    }

    @Test("A service gets one Railway domain, and a second one gives an error")
    func createRailwayDomain() async throws {
        let source = SampleDataSource()

        let domain = try await source.createRailwayDomain(
            environmentId: api.1, serviceId: api.2, token: "")

        #expect(domain.name == "api-production-sample.up.railway.app")
        #expect(await domains(source, api) == [domain])
        await #expect(throws: RailwayError.self) {
            try await source.createRailwayDomain(
                environmentId: api.1, serviceId: api.2, token: "")
        }
    }

    @Test("A new custom domain has DNS records that are not set")
    func createCustomDomain() async throws {
        let source = SampleDataSource()

        let domain = try await source.createCustomDomain(
            projectId: api.0, environmentId: api.1, serviceId: api.2, name: "api.example.com",
            token: "")

        #expect(domain.status == .needsRecords)
        #expect(
            domain.records == [
                DNSRecord(
                    type: "CNAME", name: "api", value: "sample-target.up.railway.app", isSet: false),
                DNSRecord(
                    type: "TXT", name: "_railway-verify.api", value: "railway-verify=sample",
                    isSet: false),
            ])
        #expect(await domains(source, api) == [domain])
    }

    @Test("A name that is not a domain, or that the service has, gives an error")
    func createCustomDomainFailures() async {
        let source = SampleDataSource()

        for name in ["not a domain", "shop.example.com"] {
            await #expect(throws: RailwayError.self) {
                try await source.createCustomDomain(
                    projectId: web.0, environmentId: web.1, serviceId: web.2, name: name,
                    token: "")
            }
        }
    }

    @Test("Delete removes the domain")
    func delete() async throws {
        let source = SampleDataSource()
        let custom = try #require(await domains(source, web).last)

        let didDelete = await source.deleteDomain(id: custom.id, kind: .custom, token: "")

        #expect(didDelete)
        #expect(await domains(source, web).map(\.kind) == [.railway])
        #expect(await !source.deleteDomain(id: custom.id, kind: .custom, token: ""))
    }
}
