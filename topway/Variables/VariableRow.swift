import SwiftUI
import TopwayCore

/// One variable. The value is hidden until the user selects Show.
/// All actions are always visible and have a text label.
struct VariableRow: View {
    let variable: EnvironmentVariable
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
                    Button(isValueVisible ? "Hide" : "Show") { isValueVisible.toggle() }
                        .help(isValueVisible ? "Hide the value." : "Show the value.")
                        .accessibilityLabel(isValueVisible ? "Hide value" : "Show value")

                    CopyButton(title: "Copy") { NSPasteboard.general.setSecret(variable.value) }
                        .labelStyle(.titleOnly)
                        .help("Copy the value.")
                        .accessibilityLabel("Copy value")

                    Button("Edit") { onEdit() }
                        .help("Change or delete this variable.")
                        .accessibilityLabel("Edit variable")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .frame(maxWidth: .infinity, alignment: .trailing)
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
        if isValueVisible {
            Text(variable.value)
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
