import SwiftUI
import TopwayCore

/// The cost of the billing period, the dates of the period and the usage limits.
struct SpendSummary: View {
    let spend: Spend
    /// The days that are left come from this date.
    let now: Date

    private var period: String {
        let start = spend.periodStart.formatted(date: .abbreviated, time: .omitted)
        let end = spend.periodEnd.formatted(date: .abbreviated, time: .omitted)
        let days = spend.daysLeft(now: now)
        return "\(start) to \(end) · \(days) day\(days == 1 ? "" : "s") left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.controlSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Current usage")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(spend.formattedCost)
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
                Text(period)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            // VoiceOver reads the cost and its period as one item.
            .accessibilityElement(children: .combine)

            if spend.isOverLimit {
                // Red text with a symbol, so the color is not the only sign.
                Label("The usage is above the limit.", systemImage: "exclamationmark.octagon.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            limits
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.contentInset)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, Layout.contentInset)
        }
    }

    @ViewBuilder
    private var limits: some View {
        if let use = spend.limitUse {
            ProgressView(value: min(use, 1)) {
                Text(limitText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityValue("\(Int((use * 100).rounded())) percent of the limit")
        } else {
            Text("No usage limit is set.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// Names each limit that is set. The progress bar uses the hard limit when it is set.
    private var limitText: String {
        let soft = spend.softLimit.map { "Email alert at \(Spend.dollars(Double($0)))" }
        let hard = spend.hardLimit.map { "Hard limit \(Spend.dollars(Double($0)))" }
        return [soft, hard].compactMap(\.self).joined(separator: " · ")
    }
}

#Preview {
    SpendSummary(
        spend: Spend(
            cost: 23.47, periodStart: .now - 12 * 86_400, periodEnd: .now + 18 * 86_400,
            softLimit: 50, hardLimit: 100, isOverLimit: false, usage: []),
        now: .now
    )
    .frame(width: Layout.windowWidth)
}
