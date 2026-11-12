/// The settings of a service in one environment, as Railway gives them.
struct ServiceInstanceSettings: Decodable {
    let serviceName: String
    let source: ServiceSource?
    let buildCommand: String?
    let startCommand: String?
    let rootDirectory: String?
    let healthcheckPath: String?

    /// A repository is the source when the service has one. If not, the image is the source.
    var settings: ServiceSettings {
        ServiceSettings(
            name: serviceName, source: source?.repo ?? source?.image,
            values: [
                .buildCommand: buildCommand ?? "", .startCommand: startCommand ?? "",
                .rootDirectory: rootDirectory ?? "", .healthcheckPath: healthcheckPath ?? "",
            ])
    }
}
