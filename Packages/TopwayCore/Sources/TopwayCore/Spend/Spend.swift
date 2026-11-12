import Foundation

/// The cost and the resource usage of the current billing period of a workspace.
/// Railway gives the cost. Topway calculates no price.
public struct Spend: Hashable, Sendable {
    /// The cost of the usage in US dollars, as Railway gives it (`Customer.currentUsage`).
    public let cost: Double
    public let periodStart: Date
    public let periodEnd: Date
    /// The cost in US dollars at which Railway sends an email. `nil` when it is not set.
    public let softLimit: Int?
    /// The cost in US dollars at which Railway stops the workloads. `nil` when it is not set.
    public let hardLimit: Int?
    public let isOverLimit: Bool
    /// One total for each `UsageKind`, in the order of its cases.
    public let usage: [UsageTotal]

    public init(
        cost: Double, periodStart: Date, periodEnd: Date, softLimit: Int?, hardLimit: Int?,
        isOverLimit: Bool, usage: [UsageTotal]
    ) {
        self.cost = cost
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.softLimit = softLimit
        self.hardLimit = hardLimit
        self.isOverLimit = isOverLimit
        self.usage = usage
    }

    init(customer: Customer, usage: [AggregatedUsage]) {
        let limit = customer.usageLimit
        self.init(
            cost: customer.currentUsage,
            periodStart: customer.billingPeriod.start,
            periodEnd: customer.billingPeriod.end,
            // Railway gives 0 for an email alert that is not set.
            softLimit: limit.flatMap { $0.softLimit > 0 ? $0.softLimit : nil },
            hardLimit: limit?.hardLimit,
            isOverLimit: limit?.isOverLimit ?? false,
            // Railway can give more than one value for a measurement, for example one for
            // each project. A measurement that is not a `UsageKind` is ignored.
            usage: UsageKind.allCases.map { kind in
                UsageTotal(
                    kind: kind,
                    value: usage.filter { $0.measurement == kind.rawValue }
                        .reduce(0) { $0 + $1.value })
            })
    }

    public var formattedCost: String {
        Self.dollars(cost)
    }

    /// The days until the billing period ends. A part of a day counts as one day.
    public func daysLeft(now: Date) -> Int {
        max(0, Int((periodEnd.timeIntervalSince(now) / 86_400).rounded(.up)))
    }

    /// The part of the limit that the cost uses: 1 is the limit. It uses the hard limit,
    /// or the soft limit when no hard limit is set. `nil` when no limit is set.
    public var limitUse: Double? {
        guard let limit = hardLimit ?? softLimit, limit > 0 else { return nil }
        return cost / Double(limit)
    }

    /// The text of an amount in US dollars, for example "$1,234.50".
    public static func dollars(_ amount: Double) -> String {
        // A fixed locale, because Railway bills in US dollars and the app text is English.
        amount.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))
    }
}
