import SwiftUI
import TopwayCore

/// The settings of one service: its name, and its build and deploy settings in one
/// environment. **Save changes** sends only the settings that the user changed.
struct ServiceSettingsView: View {
    @Environment(AppState.self) private var appState

    let service: Service
    let environmentId: String
    let environmentName: String
    let onDismiss: () -> Void

    /// The settings on Railway. `nil` until a load gives them.
    @State private var original: ServiceSettings?
    @State private var edited = ServiceSettings(name: "")
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var isSaved = false

    private var changes: ServiceSettingsChanges {
        original.map { edited.changes(from: $0) } ?? ServiceSettingsChanges()
    }

    /// A value that Railway has and that the user did not change stops no save.
    private var problem: ServiceSettingsProblem? {
        original.flatMap { edited.problem(comparedTo: $0) }
    }

    var body: some View {
        ScreenLayout {
            content
        } top: {
            ScreenHeader(title: "Settings", backTitle: service.name, onBack: { onDismiss() })
                .disabled(isSaving)
        } bottom: {
            // With settings on the screen, the error belongs to a save, not to the load.
            if let error = appState.errorMessage, original != nil {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        .task {
            await loadSettings()
        }
        // "Saved" is true only for the text that is in the fields.
        .onChange(of: edited) {
            if !changes.isEmpty {
                isSaved = false
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if original != nil {
            form
        } else if isLoading {
            LoadingStateView(title: "Loading settings…")
        } else {
            ErrorStateView(
                title: "Settings did not load",
                message: appState.errorMessage ?? "Select Try again to load the settings."
            ) {
                Task { await loadSettings() }
            }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("\(service.name) in \(environmentName)", systemImage: "cube")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                field(
                    "Name", text: $edited.name, example: "web",
                    hint: "The name is the same in all environments.",
                    problem: problem == .emptyName ? problem : nil
                )

                if let source = edited.source {
                    LabeledContent("Source", value: source)
                        .font(.callout)
                        .help("The repository or the image of this service. Change it on Railway.")
                }

                ForEach(ServiceSetting.allCases, id: \.self) { setting in
                    field(
                        setting.title, text: $edited[dynamicMember: \.[setting]],
                        example: setting.example,
                        problem: setting == .healthcheckPath && problem == .healthcheckPath
                            ? problem : nil
                    )
                    .font(.body.monospaced())
                }

                Text(
                    "These settings belong to \(environmentName). Railway uses its default for an empty field. A change applies to the next deployment."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, Layout.controlSpacing)
            .disabled(isSaving)
        }
    }

    private func field(
        _ title: String, text: Binding<String>, example: String, hint: String? = nil,
        problem: ServiceSettingsProblem? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.callout.weight(.medium))

            TextField(title, text: text, prompt: Text(example))
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            if let problem {
                Label {
                    Text(problem.message)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .font(.subheadline)
            } else if let hint {
                Text(hint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        ActionBar {
            if isSaved {
                Label("Saved", systemImage: "checkmark.circle.fill")
            }
        } actions: {
            Button(isSaving ? "Saving…" : "Save changes") { confirmSave() }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(changes.isEmpty || problem != nil || isSaving)
                .help("Send the changed settings to Railway (Command-Return).")
        }
    }

    // MARK: - Actions

    private func loadSettings() async {
        isLoading = true
        let fetched = await appState.fetchServiceSettings(
            environmentId: environmentId, serviceId: service.id)
        isLoading = false
        if let fetched {
            original = fetched
            edited = fetched
        }
    }

    /// The dialog uses the changes from when it opened.
    private func confirmSave() {
        let changes = changes
        guard !changes.isEmpty, problem == nil, !isSaving else { return }
        var sentences: [String] = []
        if changes.name != nil {
            sentences.append("The new name applies to all environments.")
        }
        if !changes.instance.isEmpty {
            sentences.append("The new settings apply to the next deployment in \(environmentName).")
        }
        appState.confirm(
            ConfirmationRequest(
                harm: .medium,
                title: "Save the settings of \(service.name) in \(environmentName)?",
                message: sentences.joined(separator: " "),
                actionTitle: "Save changes",
                environmentName: environmentName,
                perform: { await save(changes) }
            ))
    }

    private func save(_ changes: ServiceSettingsChanges) async {
        isSaving = true
        let didSave = await appState.updateServiceSettings(
            changes, environmentId: environmentId, serviceId: service.id)
        if didSave {
            // The fields then show what Railway has.
            await loadSettings()
            isSaved = true
            AccessibilityNotification.Announcement("Saved").post()
        }
        isSaving = false
    }
}

#Preview {
    ServiceSettingsView(
        service: Service(id: "1", name: "web-app"), environmentId: "env1",
        environmentName: "production", onDismiss: {}
    )
    .environment(AppState())
    .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
