import AppKit
import SwiftUI
import TopwayCore

/// One domain of a service: its name, its kind, the DNS records of a custom domain, and
/// its actions.
struct DomainRow: View {
    let domain: Domain
    let isDeleting: Bool
    let onRequestDelete: () -> Void

    private var statusSymbol: String {
        switch domain.status {
        case .ready: "checkmark.circle"
        case .waitingForCertificate: "clock"
        case .needsRecords, nil: "exclamationmark.triangle"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(domain.name)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(domain.name)

            HStack(spacing: Layout.controlSpacing) {
                Text(domain.kind.title)

                if let status = domain.status {
                    // The text says the status, so the symbol is not the only sign.
                    Label(status.title, systemImage: statusSymbol)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !domain.records.isEmpty {
                Text("Set these records at your DNS provider:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(domain.records) { record in
                    DNSRecordRow(record: record)
                }
            }

            HStack(spacing: 6) {
                CopyButton(title: "Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(domain.name, forType: .string)
                }
                .labelStyle(.titleOnly)
                .help("Copy the domain name.")
                .accessibilityLabel("Copy \(domain.name)")
                .accessibilityInputLabels(["Copy"])

                Button(isDeleting ? "Deleting…" : "Delete…", role: .destructive) {
                    onRequestDelete()
                }
                // The role alone does not color a bordered button on macOS.
                .foregroundStyle(.red)
                .disabled(isDeleting)
                .help("Delete this domain from the service.")
                .accessibilityLabel("\(isDeleting ? "Deleting" : "Delete") \(domain.name)")
                .accessibilityInputLabels(["Delete"])
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, Layout.contentInset)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, Layout.contentInset)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(domain.name)
    }
}
