struct DNSRecordNode: Decodable {
    let hostlabel: String
    let zone: String
    /// For example `DNS_RECORD_TYPE_CNAME`.
    let recordType: String
    let requiredValue: String
    /// For example `DNS_RECORD_STATUS_PROPAGATED`.
    let status: String

    /// `@` is the name of a record for the zone itself, as the Railway CLI shows it.
    var model: DNSRecord {
        let prefix = "DNS_RECORD_TYPE_"
        return DNSRecord(
            type: recordType.hasPrefix(prefix)
                ? String(recordType.dropFirst(prefix.count)) : recordType,
            name: hostlabel.isEmpty ? "@" : hostlabel, value: requiredValue,
            isSet: status == "DNS_RECORD_STATUS_PROPAGATED")
    }
}
