struct CustomDomainStatus: Decodable {
    let dnsRecords: [DNSRecordNode]
    let certificateStatus: String
    let verified: Bool
    /// The host of the TXT record that shows that the user owns the domain.
    let verificationDnsHost: String?
    let verificationToken: String?

    /// The records that route the traffic, then the TXT record that verifies the domain.
    /// The TXT record shows until Railway verified the domain. Its value has the prefix
    /// `railway-verify=` one time, as the Railway CLI shows it.
    var records: [DNSRecord] {
        var records = dnsRecords.map(\.model)
        if !verified, let host = verificationDnsHost, var token = verificationToken?[...] {
            let prefix = "railway-verify="
            while token.hasPrefix(prefix) {
                token = token.dropFirst(prefix.count)
            }
            // The name of a record is its host in the zone, as for the other records.
            let zone = dnsRecords.first.map { ".\($0.zone)" } ?? ""
            let name =
                !zone.isEmpty && host.hasSuffix(zone) ? String(host.dropLast(zone.count)) : host
            records.append(DNSRecord(type: "TXT", name: name, value: prefix + token, isSet: false))
        }
        return records
    }
}
