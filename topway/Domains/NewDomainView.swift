import SwiftUI
import TopwayCore

/// Adds a domain that the user owns to a service. The domains list then shows the DNS
/// records that the user must set.
struct NewDomainView: View {
    @Environment(AppState.self) private var appState

    let service: Service
    let projectId: String
    let environmentId: String
    let environmentName: String
    let existingNames: [String]
    /// `true` when Railway added the domain.
    let onDismiss: (Bool) -> Void

    @State private var name = ""
    @State private var isAdding = false
    @FocusState private var isNameFocused: Bool

    private var problem: DomainNameProblem? {
        DomainRules.problem(name: name, existingNames: existingNames)
    }

    var body: some View {
        ScreenLayout {
            form
        } top: {
            ScreenHeader(
                title: "Add custom domain", backTitle: "Domains", onBack: { cancel() }
            )
            .disabled(isAdding)
        } bottom: {
            if let error = appState.errorMessage {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        .onAppear {
            isNameFocused = true
        }
        // Escape obeys the same rule as Cancel.
        .onExitCommand {
            if appState.pendingConfirmation != nil {
                appState.cancelConfirmation()
            } else {
                cancel()
            }
        }
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("\(service.name) in \(environmentName)", systemImage: "cube")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Domain")
                        .font(.callout.weight(.medium))

                    TextField("Domain", text: $name, prompt: Text("app.example.com"))
                        .textFieldStyle(.roundedBorder)
                        .font(.body.monospaced())
                        .autocorrectionDisabled()
                        .focused($isNameFocused)
                        .onSubmit { confirmAdd() }

                    if let message = problem?.message {
                        Label {
                            Text(message)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        .font(.subheadline)
                    }

                    Text(
                        "Enter a domain that you own. Topway then shows the DNS records. Set them at your DNS provider, and Railway makes the certificate."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, Layout.controlSpacing)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        ActionBar {
            if isAdding {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Adding the domain")
            }
        } actions: {
            Button("Cancel") { cancel() }
                .buttonStyle(.glass)
                .disabled(isAdding)

            Button(isAdding ? "Adding…" : "Add domain") { confirmAdd() }
                .buttonStyle(.glassProminent)
                .disabled(problem != nil || isAdding)
        }
    }

    // MARK: - Actions

    private func cancel() {
        guard !isAdding else { return }
        onDismiss(false)
    }

    /// The dialog uses the name from when it opened.
    private func confirmAdd() {
        guard problem == nil, !isAdding else { return }
        let cleanName = DomainRules.cleanName(name)
        appState.confirm(
            ConfirmationRequest(
                harm: .medium,
                title: "Add \(cleanName) to \(service.name) in \(environmentName)?",
                message:
                    "After you set the DNS records, requests to this domain go to the service.",
                actionTitle: "Add domain",
                environmentName: environmentName,
                perform: { await add(cleanName) }
            ))
    }

    private func add(_ cleanName: String) async {
        isAdding = true
        let didAdd = await appState.addCustomDomain(
            projectId: projectId, environmentId: environmentId, serviceId: service.id,
            name: cleanName)
        isAdding = false
        if didAdd {
            onDismiss(true)
        }
    }
}

#Preview {
    NewDomainView(
        service: Service(id: "1", name: "web-app"), projectId: "1", environmentId: "env1",
        environmentName: "production", existingNames: [], onDismiss: { _ in }
    )
    .environment(AppState())
    .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
