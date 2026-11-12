import Foundation
import Testing

@testable import TopwayCore

/// The JSON has the shape of the `domains` query of Railway.
struct DomainListTests {
    private func record(_ host: String, _ type: String, _ value: String, _ status: String)
        -> String
    {
        """
        {"hostlabel":"\(host)","zone":"example.com","fqdn":"x","recordType":"DNS_RECORD_TYPE_\(type)",
         "requiredValue":"\(value)","currentValue":"","status":"DNS_RECORD_STATUS_\(status)"}
        """
    }

    private func decode(
        records: String, certificate: String, verified: Bool, token: String? = "abc123"
    ) throws -> [Domain] {
        let tokenJSON = token.map { "\"\($0)\"" } ?? "null"
        let json = """
            {"serviceDomains":[{"id":"r1","domain":"web-production.up.railway.app"}],
             "customDomains":[{"id":"c1","domain":"shop.example.com","status":{
               "dnsRecords":[\(records)],
               "certificateStatus":"CERTIFICATE_STATUS_TYPE_\(certificate)",
               "verified":\(verified),
               "verificationDnsHost":"_railway-verify.shop.example.com",
               "verificationToken":\(tokenJSON)}}]}
            """
        let domains = try JSONDecoder().decode(DomainList.self, from: Data(json.utf8)).domains
        // The tests read the two domains by index.
        try #require(domains.count == 2)
        return domains
    }

    @Test("The Railway domain is first, has no records and has no status")
    func railwayDomain() throws {
        let domains = try decode(records: "", certificate: "VALID", verified: true)

        #expect(domains.map(\.name) == ["web-production.up.railway.app", "shop.example.com"])
        #expect(domains.map(\.kind) == [.railway, .custom])
        #expect(domains[0].records.isEmpty)
        #expect(domains[0].status == nil)
    }

    @Test("A new custom domain shows its CNAME record and the TXT record that verifies it")
    func newCustomDomain() throws {
        let domains = try decode(
            records: record("shop", "CNAME", "abc.up.railway.app", "REQUIRES_UPDATE"),
            certificate: "VALIDATING_OWNERSHIP", verified: false)

        #expect(
            domains[1].records == [
                DNSRecord(type: "CNAME", name: "shop", value: "abc.up.railway.app", isSet: false),
                DNSRecord(
                    type: "TXT", name: "_railway-verify.shop", value: "railway-verify=abc123",
                    isSet: false),
            ])
        #expect(domains[1].status == .needsRecords)
    }

    @Test("The TXT value has the prefix one time, and the zone itself has the name @")
    func recordNames() throws {
        let domains = try decode(
            records: record("", "A", "203.0.113.7", "PROPAGATED"),
            certificate: "ISSUING", verified: false, token: "railway-verify=abc123")

        #expect(domains[1].records.map(\.name) == ["@", "_railway-verify.shop"])
        #expect(domains[1].records.map(\.value) == ["203.0.113.7", "railway-verify=abc123"])
        #expect(domains[1].records.map(\.isSet) == [true, false])
    }

    @Test("A verified domain has no TXT record, and waits for the certificate")
    func waitingForCertificate() throws {
        let domains = try decode(
            records: record("shop", "CNAME", "abc.up.railway.app", "PROPAGATED"),
            certificate: "ISSUING", verified: true)

        #expect(domains[1].records.map(\.type) == ["CNAME"])
        #expect(domains[1].status == .waitingForCertificate)
    }

    @Test("A domain with set records and a valid certificate is ready")
    func ready() throws {
        let domains = try decode(
            records: record("shop", "CNAME", "abc.up.railway.app", "PROPAGATED"),
            certificate: "VALID", verified: true)

        #expect(domains[1].status == .ready)
    }

    @Test("A certificate that failed has its own status and tells the user what to check")
    func certificateFailed() throws {
        let domains = try decode(
            records: record("shop", "CNAME", "abc.up.railway.app", "PROPAGATED"),
            certificate: "ISSUE_FAILED", verified: true)

        #expect(domains[1].status == .certificateFailed)
        #expect(DomainStatus.certificateFailed.title == "Certificate failed")
        #expect(DomainStatus.certificateFailed.advice?.contains("CAA record") == true)
        #expect(DomainStatus.waitingForCertificate.advice == nil)
    }

    @Test("With records that are not set, a failed certificate still asks for the records")
    func certificateFailedWithoutRecords() throws {
        let domains = try decode(
            records: record("shop", "CNAME", "abc.up.railway.app", "REQUIRES_UPDATE"),
            certificate: "ISSUE_FAILED", verified: true)

        #expect(domains[1].status == .needsRecords)
    }

    @Test("Two records with the same type and name have different ids")
    func recordIds() {
        let first = DNSRecord(type: "A", name: "@", value: "203.0.113.7", isSet: true)
        let second = DNSRecord(type: "A", name: "@", value: "203.0.113.8", isSet: true)

        #expect(first.id != second.id)
    }

    @Test("A domain that is not verified and has no token shows only its records")
    func noToken() throws {
        let domains = try decode(
            records: record("shop", "CNAME", "abc.up.railway.app", "REQUIRES_UPDATE"),
            certificate: "ISSUING", verified: false, token: nil)

        #expect(domains[1].records.map(\.type) == ["CNAME"])
    }
}
