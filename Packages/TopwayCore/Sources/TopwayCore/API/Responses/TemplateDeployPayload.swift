struct TemplateDeployPayload: Decodable {
    /// The workflow that makes the services. `nil` when Railway made them at once.
    let workflowId: String?
}
