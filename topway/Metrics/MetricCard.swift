import Charts
import SwiftUI
import TopwayCore

/// One metric: its name, its newest value, its highest value and a chart of the time range.
/// The values are text, so the chart is not the only way to read them.
struct MetricCard: View {
    let series: MetricSeries

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.controlSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: Layout.controlSpacing) {
                Text(series.kind.title)
                    .fontWeight(.medium)

                Spacer(minLength: Layout.controlSpacing)

                if let latest = series.latest, let peak = series.peak {
                    Text("Latest \(series.kind.formatted(latest))")
                    Text("Peak \(series.kind.formatted(peak))")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .monospacedDigit()
            .lineLimit(1)

            if series.samples.isEmpty {
                Text("No data in this time range.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                chart
            }
        }
        .padding(.horizontal, Layout.contentInset)
        .padding(.vertical, Layout.controlSpacing)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, Layout.contentInset)
        }
        // VoiceOver reads the name and the two values as one item.
        .accessibilityElement(children: .combine)
    }

    private var chart: some View {
        Chart(series.samples, id: \.date) { sample in
            AreaMark(x: .value("Time", sample.date), y: .value(series.kind.title, sample.value))
                .foregroundStyle(.tint.opacity(0.15))
            LineMark(x: .value("Time", sample.date), y: .value(series.kind.title, sample.value))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: Layout.chartHeight)
        // The text above gives the values. The line only shows the trend.
        .accessibilityHidden(true)
    }
}

#Preview {
    MetricCard(
        series: MetricSeries(
            kind: .cpu,
            samples: (0..<60).map {
                MetricSample(ts: $0 * 60, value: 0.4 + sin(Double($0) / 6) * 0.2)
            })
    )
    .frame(width: Layout.windowWidth)
}
