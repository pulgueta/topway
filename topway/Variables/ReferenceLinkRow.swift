import SwiftUI
import TopwayCore

/// One target of a reference variable, with its status as text and a symbol.
/// It shows names only, so it stays visible while the value is hidden.
struct ReferenceLinkRow: View {
    let link: ReferenceLink

    var body: some View {
        HStack(spacing: Layout.controlSpacing) {
            Label {
                Text(link.target.displayName)
                    .font(.subheadline.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
            } icon: {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Layout.controlSpacing)

            Label {
                Text(link.status.label)
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(isMissing ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
            }
            .font(.subheadline)
            .fixedSize()
        }
        .help(link.accessibilityDescription)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(link.accessibilityDescription)
    }

    private var isMissing: Bool {
        link.status == .missingService || link.status == .missingVariable
    }

    private var symbol: String {
        switch link.status {
        case .found: "checkmark.circle"
        case .missingService, .missingVariable: "exclamationmark.triangle"
        case .setByRailway: "info.circle"
        case .notChecked: "questionmark.circle"
        }
    }
}

#Preview {
    VStack {
        ReferenceLinkRow(
            link: ReferenceLink(
                target: ReferenceTarget(
                    namespace: .service("postgres"), variableName: "DATABASE_URL"),
                status: .found))
        ReferenceLinkRow(
            link: ReferenceLink(
                target: ReferenceTarget(namespace: .service("billing"), variableName: "API_URL"),
                status: .missingService))
    }
    .padding()
    .frame(width: Layout.windowWidth)
}
