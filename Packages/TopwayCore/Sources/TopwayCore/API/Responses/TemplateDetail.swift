struct TemplateDetail: Decodable {
    let id: String
    /// The services, variables and volumes of the template. Topway keeps all fields,
    /// also the fields that it does not know.
    let serializedConfig: JSONValue?
}
