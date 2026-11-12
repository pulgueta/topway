/// The usage limits of a workspace, in whole US dollars.
struct UsageLimit: Decodable, Sendable {
    /// 0 when no email alert is set.
    let softLimit: Int
    let hardLimit: Int?
    let isOverLimit: Bool
}
