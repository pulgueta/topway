import SwiftUI
import TopwayCore

/// The domains of one service in one environment: the list, **Add Railway domain**,
/// **Add custom domain** and **Delete…**. A custom domain shows its DNS records.
struct DomainsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let service: Service
    let projectId: String
    let environmentId: String
    let environmentName: String
    let onDismiss: () -> Void

    /// `nil` until a load gives the domains. A failed reload keeps the earlier list.
    @State private var domains: [Domain]?
    @State private var isLoading = true
    @State private var isAddingRailwayDomain = false
    @State private var deletingDomainId: String?
    @State private var isShowingForm = false
    @State private var latestLoadID = UUID()

    private var target: String {
        "\(service.name) in \(environmentName)"
    }

    var body: some View {
        ZStack {
            if isShowingForm {
                NewDomainView(
                    service: service,
                    projectId: projectId,
                    environmentId: environmentId,
                    environmentName: environmentName,
                    existingNames: (domains ?? []).map(\.name),
                    onDismiss: { didAdd in
                        showForm(false)
                        if didAdd {
                            Task { await loadDomains() }
                        }
                    }
                )
                .transition(.screen(reduceMotion: reduceMotion))
            } else {
                list
                    .transition(.opacity)
            }
        }
    }

    // MARK: - List

    private var list: some View {
        ScreenLayout {
            content
        } top: {
            ScreenHeader(title: "Domains", backTitle: service.name, onBack: { onDismiss() })

            Label(target, systemImage: "cube")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Layout.barPadding)
                .padding(.bottom, Layout.controlSpacing)
        } bottom: {
            // With a list on the screen, the error belongs to an action, not to the load.
            if let error = appState.errorMessage, domains != nil {
                ErrorBanner(message: error) { appState.clearError() }
            }
            footer
        }
        .task {
            await loadDomains()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let domains, !domains.isEmpty {
            // The list stays while a reload runs, so the screen does not flash.
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(domains) { domain in
                        DomainRow(
                            domain: domain,
                            isDeleting: deletingDomainId == domain.id,
                            onRequestDelete: { confirmDelete(of: domain) }
                        )
                    }
                }
            }
        } else if domains != nil {
            ContentUnavailableView(
                "No domains",
                systemImage: "globe",
                description: Text(
                    "This service has no domain in this environment. Select Add Railway domain to get a public address."
                )
            )
        } else if isLoading {
            LoadingStateView(title: "Loading domains…")
        } else {
            ErrorStateView(
                title: "Domains did not load",
                message: appState.errorMessage ?? "Select Try again to load the domains."
            ) {
                Task { await loadDomains() }
            }
        }
    }

    private var footer: some View {
        ActionBar {
            if isLoading && domains != nil {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Loading domains")
            }
        } actions: {
            if let domains {
                // Railway gives a service one domain of its own.
                if DomainRules.canAddRailwayDomain(to: domains) {
                    Button(isAddingRailwayDomain ? "Adding…" : "Add Railway domain") {
                        confirmAddRailwayDomain()
                    }
                    .buttonStyle(.glass)
                    .disabled(isAddingRailwayDomain)
                    .help("Get a public address on up.railway.app for this service.")
                }

                Button("Add custom domain") { showForm(true) }
                    .buttonStyle(.glass)
                    .help("Use a domain that you own for this service.")
            }
        }
    }

    // MARK: - Actions

    private func showForm(_ isVisible: Bool) {
        appState.clearError()
        withAnimation(.screenChange) {
            isShowingForm = isVisible
        }
    }

    private func loadDomains() async {
        let loadID = UUID()
        latestLoadID = loadID
        isLoading = true
        let fetched = await appState.fetchDomains(
            projectId: projectId, environmentId: environmentId, serviceId: service.id)
        // Only the latest call may update the screen.
        guard loadID == latestLoadID else { return }
        isLoading = false
        // After a failed reload, the list stays and the banner shows the error.
        if let fetched {
            domains = fetched
        }
    }

    private func confirmAddRailwayDomain() {
        appState.confirm(
            ConfirmationRequest(
                harm: .medium,
                title: "Add a Railway domain to \(target)?",
                message:
                    "Railway makes a public address for this service. "
                    + "Each person who has the address can then send requests to the service.",
                actionTitle: "Add domain",
                environmentName: environmentName,
                perform: { await addRailwayDomain() }
            ))
    }

    private func addRailwayDomain() async {
        isAddingRailwayDomain = true
        let didAdd = await appState.addRailwayDomain(
            environmentId: environmentId, serviceId: service.id)
        isAddingRailwayDomain = false
        // The list then shows the new domain.
        if didAdd {
            await loadDomains()
        }
    }

    private func confirmDelete(of domain: Domain) {
        appState.confirm(
            ConfirmationRequest(
                harm: .medium,
                title: "Delete \(domain.name) from \(target)?",
                message: domain.kind == .railway
                    ? "Requests to this address then fail. A new Railway domain can have a different name."
                    : "Requests to this domain then fail. The DNS records at your DNS provider stay.",
                actionTitle: "Delete domain",
                isDestructive: true,
                environmentName: environmentName,
                perform: { await delete(domain) }
            ))
    }

    private func delete(_ domain: Domain) async {
        deletingDomainId = domain.id
        let didDelete = await appState.deleteDomain(domain)
        deletingDomainId = nil
        if didDelete {
            await loadDomains()
        }
    }
}

#Preview {
    DomainsView(
        service: Service(id: "1", name: "web-app"), projectId: "1", environmentId: "env1",
        environmentName: "production", onDismiss: {}
    )
    .environment(AppState())
    .frame(width: Layout.windowWidth, height: Layout.windowHeight)
}
