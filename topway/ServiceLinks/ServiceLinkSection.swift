import SwiftUI
import TopwayCore

/// One service, or the shared variables: the links that start and end at it.
/// Each link is one item that VoiceOver reads as a sentence with names only.
struct ServiceLinkSection: View {
    let graph: ServiceGraph
    let node: ServiceGraphNode

    var body: some View {
        let uses = graph.uses(node)
        let usedBy = graph.usedBy(node)

        VStack(alignment: .leading, spacing: 6) {
            Text(graph.name(of: node))
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)

            if uses.isEmpty && usedBy.isEmpty {
                Text("No links")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(uses, id: \.self) { edge in
                line(edge, text: "Uses \(graph.name(of: edge.to))", symbol: "arrow.forward")
            }

            ForEach(usedBy, id: \.self) { edge in
                line(edge, text: "Used by \(graph.name(of: edge.from))", symbol: "arrow.backward")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Layout.contentInset)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, Layout.contentInset)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(graph.name(of: node))
    }

    private func line(_ edge: ServiceGraphEdge, text: String, symbol: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(edge.variableNames.joined(separator: ", "))
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if case .missingService = edge.to {
                    Label {
                        Text(ReferenceTargetStatus.missingService.label)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(graph.sentence(for: edge))
    }
}
