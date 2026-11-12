import Foundation
import Testing

@testable import TopwayCore

struct RailwayClientDomainTests {
    private let customDomain = """
        {"id":"c1","domain":"shop.example.com","status":{"dnsRecords":[
          {"hostlabel":"shop","zone":"example.com","recordType":"DNS_RECORD_TYPE_CNAME",
           "requiredValue":"abc.up.railway.app","status":"DNS_RECORD_STATUS_REQUIRES_UPDATE"}],
          "certificateStatus":"CERTIFICATE_STATUS_TYPE_VALIDATING_OWNERSHIP","verified":false,
          "verificationDnsHost":"_railway-verify.shop.example.com","verificationToken":"abc123"}}
        """

    @Test("The domains request asks for the records and the verification of a custom domain")
    func fetch() async throws {
        let server = StubServer(
            StubReply(
                body: """
                    {"data":{"domains":{"serviceDomains":[{"id":"r1","domain":"web.up.railway.app"}],
                      "customDomains":[\(customDomain)]}}}
                    """))

        let domains = try await RailwayClient(session: server.session).fetchDomains(
            projectId: "p1", environmentId: "e1", serviceId: "s1", token: "secret")

        #expect(domains.map(\.id) == ["r1", "c1"])
        #expect(domains.last?.records.count == 2)
        let query = try #require(server.requests.first?.query)
        for field in ["serviceDomains", "customDomains", "requiredValue", "verificationToken"] {
            #expect(query.contains(field))
        }
    }

    @Test("A new Railway domain gives its name")
    func createRailwayDomain() async throws {
        let server = StubServer(
            StubReply(
                body: #"{"data":{"serviceDomainCreate":{"id":"r1","domain":"web.up.railway.app"}}}"#
            ))

        let domain = try await RailwayClient(session: server.session).createRailwayDomain(
            environmentId: "e1", serviceId: "s1", token: "secret")

        #expect(domain == Domain(id: "r1", name: "web.up.railway.app", kind: .railway))
        #expect(try #require(server.requests.first?.query).contains("serviceDomainCreate"))
    }

    @Test("A new custom domain gives the DNS records that the user must set")
    func createCustomDomain() async throws {
        let server = StubServer(
            StubReply(body: #"{"data":{"customDomainCreate":\#(customDomain)}}"#))

        let domain = try await RailwayClient(session: server.session).createCustomDomain(
            projectId: "p1", environmentId: "e1", serviceId: "s1", name: "shop.example.com",
            token: "secret")

        #expect(domain.kind == .custom)
        #expect(domain.records.map(\.type) == ["CNAME", "TXT"])
        let request = try #require(server.requests.first)
        #expect(
            request.variables == [
                "projectId": "p1", "environmentId": "e1", "serviceId": "s1",
                "domain": "shop.example.com",
            ])
        #expect(try #require(request.query).contains("customDomainCreate"))
    }

    @Test(
        "Delete uses the mutation of the domain kind",
        arguments: [(DomainKind.railway, "serviceDomainDelete"), (.custom, "customDomainDelete")])
    func delete(kind: DomainKind, field: String) async throws {
        let server = StubServer(StubReply(body: #"{"data":{"\#(field)":true}}"#))

        let didDelete = try await RailwayClient(session: server.session).deleteDomain(
            id: "d1", kind: kind, token: "secret")

        #expect(didDelete)
        #expect(try #require(server.requests.first?.query).contains("\(field)(id: $id)"))
    }
}
