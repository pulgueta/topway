/// The log query and subscription use the alias `lines`, so build logs and deploy logs
/// decode to the same type.
struct LogsData: Decodable, Sendable {
    let lines: [LogLine]
}
