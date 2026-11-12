import Testing
import TopwayCore

struct DomainRulesTests {
    @Test(
        "The clean name is lowercase, with no scheme, path, spaces or last dot",
        arguments: [
            ("  App.Example.com ", "app.example.com"),
            ("https://app.example.com/path?x=1", "app.example.com"),
            ("HTTP://example.com", "example.com"),
            ("example.com.", "example.com"),
        ])
    func cleanName(text: String, clean: String) {
        #expect(DomainRules.cleanName(text) == clean)
    }

    @Test(
        "A domain name with correct labels is permitted",
        arguments: [
            "example.com", "app.example.com", "a-b.example.co.uk", "xn--bcher-kva.example",
            "*.example.com", "https://Shop.Example.com/", "1app.example.com",
        ])
    func valid(name: String) {
        #expect(DomainRules.problem(name: name, existingNames: []) == nil)
    }

    @Test(
        "A name that is not a domain name is not permitted",
        arguments: [
            "localhost", "exa mple.com", "-a.example.com", "a-.example.com", "a..com",
            "example.123", "app_1.example.com", "*.com", "a.*.example.com", "exämple.com",
            String(repeating: "a", count: 64) + ".example.com",
            Array(repeating: String(repeating: "a", count: 60), count: 5).joined(separator: ".")
                + ".com",
        ])
    func invalid(name: String) {
        let problem = DomainRules.problem(name: name, existingNames: [])

        #expect(problem == .invalid)
        #expect(problem?.message == "Enter a domain name, for example app.example.com.")
    }

    @Test("An empty name is not permitted, and it shows no message", arguments: ["", "  "])
    func empty(name: String) {
        let problem = DomainRules.problem(name: name, existingNames: [])

        #expect(problem == .empty)
        #expect(problem?.message == nil)
    }

    @Test(
        "A domain that only Railway can make is not a custom domain",
        arguments: ["web-production.up.railway.app", "Web.Railway.App"])
    func railwayDomain(name: String) {
        #expect(DomainRules.problem(name: name, existingNames: []) == .railwayDomain)
    }

    @Test("A domain that the service has is not permitted")
    func duplicate() {
        #expect(
            DomainRules.problem(
                name: "https://Shop.example.com", existingNames: ["shop.example.com"])
                == .duplicate)
    }

    @Test("A service gets one Railway domain")
    func oneRailwayDomain() {
        let custom = Domain(id: "c1", name: "shop.example.com", kind: .custom)
        let railway = Domain(id: "r1", name: "web.up.railway.app", kind: .railway)

        #expect(DomainRules.canAddRailwayDomain(to: []))
        #expect(DomainRules.canAddRailwayDomain(to: [custom]))
        #expect(!DomainRules.canAddRailwayDomain(to: [custom, railway]))
    }
}
