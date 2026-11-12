import SwiftUI
import TopwayCore

/// Adds a variable, or changes or deletes one.
struct EditVariableView: View {
    @Environment(AppState.self) private var appState

    let projectId: String
    let environmentId: String
    let serviceId: String
    let serviceName: String
    let environmentName: String
    let existingVariable: EnvironmentVariable?
    /// The names of the variables in this environment. `nil` means the names are not known.
    let existingNames: Set<String>?
    /// The names of the sealed variables in this environment. A save must not put an empty
    /// value over one of them, also from Add variable.
    let sealedNames: Set<String>
    /// The services of the project, for the reference menu and the suggestions.
    let services: [Service]
    /// `nil` when the variables of the other services did not load.
    let projectVariables: ProjectVariables?
    let onDismiss: () -> Void
    let onSave: () -> Void

    @State private var name: String = ""
    @State private var value: String = ""
    @State private var selection: TextSelection?
    @State private var isSaving = false
    @State private var isDeleting = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case value
    }

    private var isEditing: Bool {
        existingVariable != nil
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && EnvironmentVariable.permitsSave(of: value, as: name, sealedNames: allSealedNames)
    }

    /// The sealed names, with the edited variable when it is sealed.
    private var allSealedNames: Set<String> {
        guard let existingVariable, existingVariable.isSealed else { return sealedNames }
        return sealedNames.union([existingVariable.name])
    }

    private var isSealedTarget: Bool {
        allSealedNames.contains(name.trimmingCharacters(in: .whitespaces))
    }

    /// The variables that the value can reference. The variable itself is left out.
    private var referenceGroups: [ReferenceGroup] {
        projectVariables?.referenceGroups(
            for: serviceId, services: services,
            excluding: name.trimmingCharacters(in: .whitespaces)) ?? []
    }

    /// The selection of the value, or `nil` when it is not a range of the current value.
    private var selectedRange: Range<String.Index>? {
        guard let selection, case .selection(let range) = selection.indices,
            range.lowerBound >= value.startIndex, range.upperBound <= value.endIndex
        else { return nil }
        return range
    }

    /// The reference that the user types at the cursor.
    private var completion: ReferenceCompletion? {
        guard let range = selectedRange, range.isEmpty else { return nil }
        return ReferenceCompletion(text: value, cursor: range.upperBound)
    }

    private var suggestions: [ReferenceTarget] {
        completion?.matches(in: referenceGroups.flatMap(\.targets)) ?? []
    }

    var body: some View {
        ScreenLayout {
            form
        } top: {
            ScreenHeader(
                title: isEditing ? "Edit variable" : "Add variable",
                backTitle: "Variables",
                onBack: { cancelEditing() }
            )
        } bottom: {
            if let error = appState.errorMessage {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        .onAppear {
            appState.clearError()
            if let variable = existingVariable {
                name = variable.name
                // A sealed variable has no value to show, so the editor starts empty.
                value = variable.value ?? ""
            }
            // The name of a saved variable cannot change, so the value gets the focus.
            focusedField = isEditing ? .value : .name
        }
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("\(serviceName) in \(environmentName)", systemImage: "cube")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.callout.weight(.medium))

                    TextField("Name", text: $name, prompt: Text("VARIABLE_NAME"))
                        .textFieldStyle(.roundedBorder)
                        .font(.body.monospaced())
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .disabled(isEditing)

                    Text(
                        isEditing
                            ? "You cannot change the name of a saved variable."
                            : "Use uppercase letters, digits and underscores."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Value")
                        .font(.callout.weight(.medium))

                    if isSealedTarget {
                        Label(
                            "This variable is sealed. Railway does not show its value. "
                                + "Type a new value to replace it.",
                            systemImage: "lock"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    // A text editor keeps the line breaks of a value with many lines.
                    TextEditor(text: $value, selection: $selection)
                        .font(.body.monospaced())
                        .autocorrectionDisabled()
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 96, maxHeight: 140)
                        .padding(6)
                        .background(.background.secondary, in: .rect(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(.separator)
                        }
                        .focused($focusedField, equals: .value)
                        .accessibilityLabel("Value")

                    if !suggestions.isEmpty {
                        ReferenceSuggestions(targets: suggestions) { target in
                            complete(with: target)
                        }
                    }

                    HStack(spacing: Layout.controlSpacing) {
                        ReferenceMenu(
                            groups: referenceGroups, isLoaded: projectVariables != nil,
                            onInsert: { target in insert(target) })

                        Text("Or type ${{ in the value.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("The service uses the value after the next deploy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, Layout.controlSpacing)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        ActionBar {
            if isEditing {
                Button("Delete variable…", role: .destructive) { confirmDelete() }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                    .disabled(isDeleting || isSaving)
                    .help("Remove this variable from \(serviceName) in \(environmentName).")
            }
        } actions: {
            Button("Cancel") { cancelEditing() }
                .buttonStyle(.glass)

            Button(isEditing ? "Save changes" : "Add variable") { confirmSave() }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!isFormValid || isSaving || isDeleting)
                .help(isEditing ? "Save the new value (⌘Return)." : "Add the variable (⌘Return).")
        }
    }

    // MARK: - Actions

    /// Puts the reference in place of the selection, or at the end of the value.
    private func insert(_ target: ReferenceTarget) {
        let range = selectedRange ?? value.endIndex..<value.endIndex
        let result = target.insert(into: value, replacing: range)
        value = result.text
        selection = TextSelection(insertionPoint: result.cursor)
        focusedField = .value
    }

    private func complete(with target: ReferenceTarget) {
        guard let completion else { return }
        let result = completion.insert(target, into: value)
        value = result.text
        selection = TextSelection(insertionPoint: result.cursor)
        focusedField = .value
    }

    // Only a user exit clears the error. A failed refresh must stay visible.
    private func cancelEditing() {
        appState.clearError()
        onDismiss()
    }

    private func confirmSave() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let confirmedValue = value
        appState.confirm(
            ConfirmationRequest(
                harm: ConfirmationRules.variableSaveHarm(
                    name: trimmedName, isEditing: isEditing, existingNames: existingNames),
                title: "Update \(trimmedName)?",
                message:
                    "This sets the value for \(serviceName) in \(environmentName). "
                    + "The service uses the new value after the next deploy.",
                actionTitle: "Update variable",
                environmentName: environmentName,
                perform: { await saveVariable(name: trimmedName, value: confirmedValue) }
            ))
    }

    private func confirmDelete() {
        let confirmedName = name
        appState.confirm(
            ConfirmationRequest(
                harm: .medium,
                title: "Delete \(confirmedName)?",
                message:
                    "This removes the variable from \(serviceName) in \(environmentName). "
                    + "You cannot undo this.",
                actionTitle: "Delete variable",
                isDestructive: true,
                environmentName: environmentName,
                perform: { await deleteVariable(name: confirmedName) }
            ))
    }

    private func saveVariable(name: String, value: String) async {
        isSaving = true

        let success = await appState.upsertVariable(
            projectId: projectId,
            environmentId: environmentId,
            serviceId: serviceId,
            name: name,
            value: value
        )

        isSaving = false

        if success {
            onSave()
            onDismiss()
        }
    }

    private func deleteVariable(name: String) async {
        isDeleting = true

        let success = await appState.deleteVariable(
            projectId: projectId,
            environmentId: environmentId,
            serviceId: serviceId,
            name: name
        )

        isDeleting = false

        if success {
            onSave()
            onDismiss()
        }
    }
}

#Preview {
    EditVariableView(
        projectId: "proj1",
        environmentId: "env1",
        serviceId: "svc1",
        serviceName: "web-app",
        environmentName: "production",
        existingVariable: nil,
        existingNames: [],
        sealedNames: [],
        services: [Service(id: "svc2", name: "postgres")],
        projectVariables: ProjectVariables(
            shared: ["LOG_LEVEL": "info"], byService: ["svc2": ["DATABASE_URL": "postgresql://db"]]),
        onDismiss: {},
        onSave: {}
    )
    .environment(AppState())
    .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
