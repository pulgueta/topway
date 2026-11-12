import AppKit
import SwiftUI
import TopwayCore

/// One DNS record of a custom domain: its type, its name, the value that it must have, and
/// if Railway sees the value in the DNS.
struct DNSRecordRow: View {
    let record: DNSRecord

    var body: some View {
        // Each record has the same button, so the accessibility label names the record.
        let name = "\(record.type) record \(record.name)"

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: Layout.controlSpacing) {
                Text("\(record.type) \(record.name)")
                    .font(.callout.monospaced().weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: Layout.controlSpacing)

                // The text says the state, so the symbol is not the only sign.
                Label(
                    record.isSet ? "Set" : "Not set",
                    systemImage: record.isSet ? "checkmark.circle" : "clock"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: Layout.controlSpacing) {
                Text(record.value)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(record.value)
                    .frame(maxWidth: .infinity, alignment: .leading)

                CopyButton(title: "Copy value") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(record.value, forType: .string)
                }
                .labelStyle(.titleOnly)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Copy the value of this record.")
                .accessibilityLabel("Copy value of \(name)")
                .accessibilityInputLabels(["Copy value"])
            }
        }
        .padding(8)
        .background(.primary.opacity(0.05), in: .rect(cornerRadius: Layout.rowCornerRadius))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(name)
    }
}
