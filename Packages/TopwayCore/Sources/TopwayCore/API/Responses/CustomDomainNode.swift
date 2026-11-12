struct CustomDomainNode: Decodable {
    let id: String
    let domain: String
    let status: CustomDomainStatus

    var model: Domain {
        Domain(
            id: id, name: domain, kind: .custom, records: status.records,
            hasCertificate: status.certificateStatus == "CERTIFICATE_STATUS_TYPE_VALID",
            didCertificateFail: status.certificateStatus
                == "CERTIFICATE_STATUS_TYPE_ISSUE_FAILED")
    }
}
