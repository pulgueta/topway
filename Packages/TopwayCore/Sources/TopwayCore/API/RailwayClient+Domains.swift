extension RailwayClient {
    /// The fields of a custom domain that give its DNS records and its status.
    private static let customDomainFields = """
        id
        domain
        status {
          dnsRecords {
            hostlabel
            zone
            recordType
            requiredValue
            status
          }
          certificateStatus
          verified
          verificationDnsHost
          verificationToken
        }
        """

    public func fetchDomains(
        projectId: String, environmentId: String, serviceId: String, token: String
    ) async throws -> [Domain] {
        let query = """
            query Domains($projectId: String!, $environmentId: String!, $serviceId: String!) {
              domains(projectId: $projectId, environmentId: $environmentId, serviceId: $serviceId) {
                serviceDomains {
                  id
                  domain
                }
                customDomains {
                  \(Self.customDomainFields)
                }
              }
            }
            """

        let data: DomainsData = try await execute(
            query: query,
            variables: [
                "projectId": projectId, "environmentId": environmentId, "serviceId": serviceId,
            ],
            token: token
        )
        return data.domains.domains
    }

    public func createRailwayDomain(environmentId: String, serviceId: String, token: String)
        async throws -> Domain
    {
        let mutation = """
            mutation ServiceDomainCreate($environmentId: String!, $serviceId: String!) {
              serviceDomainCreate(input: { environmentId: $environmentId, serviceId: $serviceId }) {
                id
                domain
              }
            }
            """

        let data: ServiceDomainCreateData = try await execute(
            query: mutation,
            variables: ["environmentId": environmentId, "serviceId": serviceId],
            token: token
        )
        return data.serviceDomainCreate.model
    }

    public func createCustomDomain(
        projectId: String, environmentId: String, serviceId: String, name: String, token: String
    ) async throws -> Domain {
        let mutation = """
            mutation CustomDomainCreate(
              $projectId: String!
              $environmentId: String!
              $serviceId: String!
              $domain: String!
            ) {
              customDomainCreate(
                input: {
                  projectId: $projectId
                  environmentId: $environmentId
                  serviceId: $serviceId
                  domain: $domain
                }
              ) {
                \(Self.customDomainFields)
              }
            }
            """

        let data: CustomDomainCreateData = try await execute(
            query: mutation,
            variables: [
                "projectId": projectId, "environmentId": environmentId, "serviceId": serviceId,
                "domain": name,
            ],
            token: token
        )
        return data.customDomainCreate.model
    }

    public func deleteDomain(id: String, kind: DomainKind, token: String) async throws -> Bool {
        // A mutation name of Topway, not user input.
        let field = kind == .railway ? "serviceDomainDelete" : "customDomainDelete"
        let mutation = """
            mutation DomainDelete($id: String!) {
              \(field)(id: $id)
            }
            """

        let data: [String: Bool] = try await execute(
            query: mutation, variables: ["id": id], token: token)
        guard let result = data[field] else { throw RailwayError.unknown }
        return result
    }
}
