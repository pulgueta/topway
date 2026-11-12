import SwiftUI
import TopwayCore

/// Inserts a reference: select a service, then one of its variables.
/// The menu has text labels, so it works with the keyboard, VoiceOver and Voice Control.
struct ReferenceMenu: View {
    let groups: [ReferenceGroup]
    /// `false` when the variables of the other services did not load.
    let isLoaded: Bool
    let onInsert: (ReferenceTarget) -> Void

    var body: some View {
        Menu("Insert reference", systemImage: "link") {
            ForEach(groups) { group in
                Menu(group.title) {
                    ForEach(group.targets, id: \.self) { target in
                        Button(target.variableName) { onInsert(target) }
                    }
                }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .fixedSize()
        .disabled(groups.isEmpty)
        .help(help)
    }

    private var help: String {
        if !isLoaded {
            return "The variables of the other services did not load."
        }
        return groups.isEmpty
            ? "There are no variables to insert."
            : "Insert a reference to a variable at the cursor."
    }
}
