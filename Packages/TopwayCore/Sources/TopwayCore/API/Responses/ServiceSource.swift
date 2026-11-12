/// What Railway builds or runs for a service: a repository or an image.
struct ServiceSource: Decodable {
    let image: String?
    let repo: String?
}
