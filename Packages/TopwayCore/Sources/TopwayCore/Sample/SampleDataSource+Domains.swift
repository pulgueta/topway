/// The sample domains of a service. The names end in `example.com` or have the word
/// "sample", and the app does not open them.
extension SampleDataSource {
    static let seedDomains: [String: [Domain]] = [
        "storefront-production/storefront-web": [
            Domain(
                id: "domain-seed-1", name: "web-production-sample.up.railway.app", kind: .railway),
            Domain(
                id: "domain-seed-2", name: "shop.example.com", kind: .custom,
                records: [
                    DNSRecord(
                        type: "CNAME", name: "shop", value: "sample-target.up.railway.app",
                        isSet: true)
                ], hasCertificate: true),
        ]
    ]

    public func fetchDomains(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) -> [Domain] {
        let all = domains[Self.key(environmentId, serviceId)] ?? []
        return all.filter { $0.kind == .railway } + all.filter { $0.kind == .custom }
    }

    /// Throws when the service does not exist or has a Railway domain.
    public func createRailwayDomain(environmentId: String, serviceId: String, token: String)
        throws -> Domain
    {
        let key = Self.key(environmentId, serviceId)
        guard
            let project = projects.first(where: {
                $0.serviceList.contains { $0.id == serviceId }
            }),
            let service = project.serviceList.first(where: { $0.id == serviceId }),
            let environment = project.environmentList.first(where: { $0.id == environmentId })
        else { throw RailwayError.graphQLError("Service not found.") }
        guard DomainRules.canAddRailwayDomain(to: domains[key] ?? []) else {
            throw RailwayError.graphQLError("The service has a Railway domain.")
        }
        return add(
            Domain(
                id: nextDomainId(),
                name: "\(service.name)-\(environment.name)-sample.up.railway.app",
                kind: .railway), key: key)
    }

    /// The new domain has a CNAME record and a TXT record that are not set, as a new
    /// domain on Railway. Throws when the name is not a domain name or the service has it.
    public func createCustomDomain(
        projectId: String, environmentId: String, serviceId: String, name: String, token: String
    ) throws -> Domain {
        let key = Self.key(environmentId, serviceId)
        let existing = (domains[key] ?? []).map(\.name)
        guard DomainRules.problem(name: name, existingNames: existing) == nil else {
            throw RailwayError.graphQLError("The domain is not valid or is in use.")
        }
        let clean = DomainRules.cleanName(name)
        // The last two labels are the zone. The labels before them are the host.
        let host = clean.split(separator: ".").dropLast(2).joined(separator: ".")
        return add(
            Domain(
                id: nextDomainId(), name: clean, kind: .custom,
                records: [
                    DNSRecord(
                        type: "CNAME", name: host.isEmpty ? "@" : host,
                        value: "sample-target.up.railway.app", isSet: false),
                    DNSRecord(
                        type: "TXT",
                        name: host.isEmpty ? "_railway-verify" : "_railway-verify.\(host)",
                        value: "railway-verify=sample", isSet: false),
                ]), key: key)
    }

    /// Returns `false` when the domain does not exist.
    public func deleteDomain(id: String, kind: DomainKind, token: String) -> Bool {
        guard let key = domains.first(where: { $0.value.contains { $0.id == id } })?.key else {
            return false
        }
        domains[key]?.removeAll { $0.id == id }
        return true
    }

    // MARK: - Private Methods

    private func nextDomainId() -> String {
        domainCount += 1
        return "domain-\(domainCount)"
    }

    private func add(_ domain: Domain, key: String) -> Domain {
        domains[key, default: []].append(domain)
        return domain
    }
}
