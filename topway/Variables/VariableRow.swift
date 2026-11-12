import SwiftUI
import TopwayCore

/// One variable. The value is hidden until the user selects Show.
/// All actions are always visible and have a text label.
/// A value with references also shows each target and its status.
/// A sealed variable has no value, so it shows "Sealed" and has no Show and no Copy.
struct VariableRow: View {
    let variable: EnvironmentVariable
    /// The targets of the references in the value. Empty for a value with no reference.
    var links: [ReferenceLink] = []
    let onEdit: () -> Void

    @State private var isValueVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(variable.name)
                .font(.callout.monospaced().weight(.medium))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(variable.name)

            // A hidden value shares a line with the actions. A visible value gets the full width.
            valueLayout {
                value
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    if let secret = variable.value {
                        Button(isValueVisible ? "Hide" : "Show") { isValueVisible.toggle() }
                            .help(isValueVisible ? "Hide the value." : "Show the value.")
                            .accessibilityLabel(
                                "\(isValueVisible ? "Hide" : "Show") value of \(variable.name)"
                            )
                            .accessibilityInputLabels([isValueVisible ? "Hide" : "Show"])

                        CopyButton(title: "Copy") { NSPasteboard.general.setSecret(secret) }
                            .labelStyle(.titleOnly)
                            .help("Copy the value.")
                            .accessibilityLabel("Copy value of \(variable.name)")
                            .accessibilityInputLabels(["Copy"])
                    }

                    Button("Edit") { onEdit() }
                        .help("Change or delete this variable.")
                        .accessibilityLabel("Edit \(variable.name)")
                        .accessibilityInputLabels(["Edit"])
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ForEach(links) { link in
                ReferenceLinkRow(link: link)
            }
        }
        .padding(.horizontal, Layout.contentInset)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, Layout.contentInset)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(variable.name)
    }

    private var valueLayout: AnyLayout {
        isValueVisible
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 6))
    }

    @ViewBuilder
    private var value: some View {
        if variable.isSealed {
            Label("Sealed", systemImage: "lock")
                .help("Railway does not show the value of a sealed variable.")
                .accessibilityLabel("Sealed value")
        } else if isValueVisible, let secret = variable.value {
            Text(secret)
                .lineLimit(4)
                .textSelection(.enabled)
        } else {
            // A fixed length does not show the length of the value.
            Text(String(repeating: "•", count: 12))
                .accessibilityLabel("Hidden value")
        }
    }
}

#Preview {
    VariableRow(
        variable: EnvironmentVariable(name: "DATABASE_URL", value: "postgres://db"), onEdit: {}
    )
    .frame(width: Layout.windowWidth)
}
