/// The billing account of a workspace.
struct Customer: Decodable, Sendable {
    /// The cost of the usage in the billing period, in US dollars. Railway keeps this value
    /// in a cache, so it can be some minutes old.
    let currentUsage: Double
    let billingPeriod: BillingPeriod
    let usageLimit: UsageLimit?
}
