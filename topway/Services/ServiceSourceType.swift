/// Where Railway gets the code of a new service.
enum ServiceSourceType: Hashable {
    case gitHub
    case docker
    /// A database from a Railway template.
    case database
}
