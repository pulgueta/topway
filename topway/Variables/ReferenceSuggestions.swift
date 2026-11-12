import SwiftUI
import TopwayCore

/// The targets that match the reference that the user types after `${{`.
/// Each suggestion is a button with its text, so no suggestion shows only on hover.
struct ReferenceSuggestions: View {
    let targets: [ReferenceTarget]
    let onSelect: (ReferenceTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Suggestions")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(targets, id: \.self) { target in
                Button(target.expression) { onSelect(target) }
                    .font(.callout.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help("Insert \(target.template).")
                    .accessibilityLabel("Insert reference to \(target.displayName)")
                    .accessibilityInputLabels([target.expression])
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Suggestions")
        // The list shows while the user types, away from the focused control.
        .onAppear {
            AccessibilityNotification.Announcement("Suggestions are below the value.").post()
        }
    }
}
