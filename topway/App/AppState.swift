import Foundation
import SwiftUI
import TopwayCore

@MainActor
@Observable
class AppState {
    // MARK: - Published Properties

    var projects: [Project] = []
    var isLoading = false
    /// A new message does not belong to the token, unless `show(_:)` sets the flag after it.
    var errorMessage: String? {
        didSet { isTokenRejected = false }
    }
    /// `true` while `errorMessage` says that Railway did not accept the token.
    private(set) var isTokenRejected = false
    var pendingConfirmation: ConfirmationRequest?
    var isRunningConfirmation = false
    /// Sample mode shows the data of `SampleDataSource`. It never reads or writes the
    /// Keychain token, and it ends when the app quits.
    private(set) var isSampleMode = false
    /// The open incident that Railway reports. `nil` with no incident and before the
    /// first check.
    private(set) var incident: PlatformIncident?

    // MARK: - Sign-in

    /// The client ID of the Railway OAuth app, from the build. `nil` in a build with no
    /// client ID: Topway then offers only sample data.
    let oauthClientID = RailwayOAuth.clientID(
        fromInfoValue: Bundle.main.object(forInfoDictionaryKey: RailwayOAuth.clientIDInfoKey))
    /// `true` while the sign-in window is open or the code exchange runs.
    private(set) var isSigningIn = false
    /// Why the last sign-in failed. The start screen shows it with **Try again**.
    private(set) var signInError: String?
    /// Why the start screen shows after a sign-in ended, for example a refresh token that
    /// Railway does not accept.
    private(set) var sessionNotice: String?
    /// The signed-in user and the workspaces that the user shared. `nil` until it loads.
    private(set) var account: RailwayAccount?

    private static let tokensKey = "railwayOAuth"
    /// The Keychain item and the `UserDefaults` key of the API token of earlier builds.
    private static let legacyTokenKey = "railwayToken"
    static let notConnectedMessage = "Sign in with Railway and select a workspace first."

    /// In-memory copy of the Keychain item, so a request does not read the Keychain.
    private var tokens: OAuthTokens?
    /// The refresh that runs. Other requests wait for it, so Topway never sends one refresh
    /// token two times: Railway ends the whole authorization when it gets a rotated refresh
    /// token.
    private var tokenRefresh: Task<OAuthTokens, any Error>?
    private let oauthClient = RailwayOAuthClient()
    /// The account query is not in `RailwayDataSource`, because sample mode has no account.
    private let accountClient = RailwayClient()
    /// Changes on a new sign-in, a sign-out and sample mode. A late result of an earlier
    /// sign-in or account load then changes nothing.
    private var sessionGeneration = SessionGeneration()
    /// The open sign-in window. A sign-out or sample data closes it.
    private var webSignIn: WebSignIn?

    /// Persisted in `UserDefaults`, but held as a stored property so `@Observable`
    /// tracks it. A computed accessor that read `UserDefaults` directly would not
    /// register as a dependency, so views (e.g. `isConfigured` in `MainView`)
    /// wouldn't update when it changed. `didSet` does not fire for the default
    /// value during `init`, so no side effects run at startup.
    var workspaceId: String = UserDefaults.standard.string(forKey: "workspaceId") ?? "" {
        didSet {
            UserDefaults.standard.set(workspaceId, forKey: "workspaceId")
            // The projects of a different workspace must not cause false alerts.
            if workspaceId != oldValue {
                alertSnapshot = nil
            }
        }
    }

    /// Off by default. Turning it on asks for notification permission.
    var alertsEnabled: Bool = UserDefaults.standard.bool(forKey: "alertsEnabled") {
        didSet { UserDefaults.standard.set(alertsEnabled, forKey: "alertsEnabled") }
    }

    /// The projects that send no alerts.
    private(set) var mutedProjectIds = Set(
        UserDefaults.standard.stringArray(forKey: "mutedProjectIds") ?? [])
    {
        didSet {
            UserDefaults.standard.set(mutedProjectIds.sorted(), forKey: "mutedProjectIds")
        }
    }

    var autoRefreshEnabled: Bool = UserDefaults.standard.bool(forKey: "autoRefreshEnabled") {
        didSet {
            UserDefaults.standard.set(autoRefreshEnabled, forKey: "autoRefreshEnabled")
            if autoRefreshEnabled {
                startAutoRefresh()
            } else {
                stopAutoRefresh()
            }
        }
    }

    var autoRefreshInterval: TimeInterval = {
        let interval = UserDefaults.standard.double(forKey: "autoRefreshInterval")
        return interval > 0 ? interval : 30  // Default 30 seconds
    }()
    {
        didSet {
            UserDefaults.standard.set(autoRefreshInterval, forKey: "autoRefreshInterval")
            if autoRefreshEnabled {
                restartAutoRefresh()
            }
        }
    }

    // MARK: - Private Properties

    private var dataSource: any RailwayDataSource = RailwayClient()
    private var refreshTask: Task<Void, Never>?
    /// The action of the confirmation dialog while it runs.
    private var confirmationTask: Task<Void, Never>?
    /// The message that the latest failed background refresh set.
    private var refreshFailureMessage: String?
    /// Only the latest project load may change the screen. A data source switch also
    /// increases it, so a load from the earlier source is dropped.
    private var latestProjectLoad = 0
    /// Only the latest metrics load may show an error. A newer load replaces an earlier one.
    private var latestMetricsLoad = 0
    private var latestSpendLoad = 0
    /// The last settled state of each service. It is `nil` before the first load of a data
    /// source or a workspace, so that load gives no alerts.
    private var alertSnapshot: AlertSnapshot?
    private var lastIncidentCheck: Date?
    /// A data source switch increases it, so an answer of the earlier source is dropped.
    private var incidentGeneration = 0
    /// The incident that the user hid. A different incident shows again.
    private var hiddenIncidentId: String?
    /// The incident that VoiceOver said last. No view reads it.
    @ObservationIgnored private var announcedIncidentId: String?

    // MARK: - Init

    init() {
        // Sign in with Railway replaced the API token. Topway does not use a token of an
        // earlier build: it removes the token, and the user sees the start screen.
        KeychainStore.delete(Self.legacyTokenKey)
        UserDefaults.standard.removeObject(forKey: Self.legacyTokenKey)

        if oauthClientID != nil, let saved = KeychainStore.read(Self.tokensKey) {
            tokens = OAuthTokens(keychainValue: saved)
        }
        // With no sign-in, a saved workspace belongs to nobody. This also removes the
        // Workspace ID that an earlier build saved with its API token.
        if tokens == nil {
            UserDefaults.standard.removeObject(forKey: "workspaceId")
            workspaceId = ""
        }
    }

    // MARK: - Computed Properties

    var isSignedIn: Bool {
        tokens != nil
    }

    /// `false` in a build with no client ID.
    var canSignIn: Bool {
        oauthClientID != nil
    }

    var isConfigured: Bool {
        isSampleMode || (isSignedIn && !workspaceId.isEmpty)
    }

    /// Signed in, but the user must choose a workspace first.
    var needsWorkspace: Bool {
        !isSampleMode && isSignedIn && workspaceId.isEmpty
    }

    var hasError: Bool {
        errorMessage != nil
    }

    /// What the user can do when a load fails. The most useful action is first.
    var recoveryActions: [RecoveryAction] {
        RecoveryRules.actions(isTokenRejected: isTokenRejected, isSampleMode: isSampleMode)
    }

    var health: HealthSummary {
        HealthSummary(projects: projects)
    }

    /// The incident for the banner. `nil` when the user hid this incident.
    var visibleIncident: PlatformIncident? {
        incident?.id == hiddenIncidentId ? nil : incident
    }

    // MARK: - Public Methods

    func loadProjects(keepingError: Bool = false) async {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return
        }

        isLoading = true
        if !keepingError {
            errorMessage = nil
        }
        // Not awaited, so a slow status answer does not delay the projects.
        Task { await checkIncident() }

        latestProjectLoad += 1
        let load = latestProjectLoad
        do {
            let fetchedProjects = try await withAccessToken { source, token in
                try await source.fetchProjects(
                    workspaceId: workspaceId,
                    token: token
                )
            }
            guard load == latestProjectLoad else { return }
            projects = fetchedProjects
            sendAlerts(for: fetchedProjects)
            if let refreshFailureMessage, errorMessage == refreshFailureMessage {
                errorMessage = nil
            }
            refreshFailureMessage = nil
        } catch let error as RailwayError {
            guard load == latestProjectLoad else { return }
            show(error)
            // A cancellation sets no message, so `errorMessage` can belong to a user action.
            if error.errorDescription != nil {
                refreshFailureMessage = keepingError ? errorMessage : nil
            }
        } catch {
            guard load == latestProjectLoad else { return }
            errorMessage = error.localizedDescription
            refreshFailureMessage = keepingError ? errorMessage : nil
        }

        isLoading = false
    }

    func createService(projectId: String, repo: String) async -> Bool {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await withAccessToken { source, token in
                try await source.createService(
                    projectId: projectId,
                    repo: repo,
                    token: token
                )
            }
            // Refresh projects to show the new service
            await loadProjects()
            return true
        } catch let error as RailwayError {
            show(error)
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func createServiceWithImage(projectId: String, image: String) async -> Bool {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await withAccessToken { source, token in
                try await source.createServiceWithImage(
                    projectId: projectId,
                    image: image,
                    token: token
                )
            }
            // Refresh projects to show the new service
            await loadProjects()
            return true
        } catch let error as RailwayError {
            show(error)
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    /// Returns `nil` when the fetch fails or is cancelled. An empty array means no variables.
    func fetchVariables(projectId: String, environmentId: String, serviceId: String) async
        -> [EnvironmentVariable]?
    {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return nil
        }

        errorMessage = nil

        do {
            let variables = try await withAccessToken { source, token in
                try await source.fetchVariables(
                    projectId: projectId,
                    environmentId: environmentId,
                    serviceId: serviceId,
                    token: token
                )
            }
            return variables.map { EnvironmentVariable(name: $0.key, value: $0.value) }
                .sorted { $0.name < $1.name }
        } catch let error as RailwayError {
            show(error)
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func deleteProject(projectId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let success = try await withAccessToken { source, token in
                try await source.deleteProject(
                    projectId: projectId,
                    token: token
                )
            }
            // Reconcile with the server regardless of the result: a project that
            // was already deleted (or is mid-deletion) then drops out of the
            // refreshed list instead of lingering in the UI.
            await loadProjects()
            if !success {
                errorMessage = "Railway did not delete the project. Try again."
            }
            return success
        } catch let error as RailwayError {
            await loadProjects()
            show(error)
            return false
        } catch {
            let description = error.localizedDescription
            await loadProjects()
            errorMessage = description
            return false
        }
    }

    private func show(_ error: RailwayError) {
        if case .cancelled = error { return }
        errorMessage = error.errorDescription
        isTokenRejected = error.isTokenRejected
    }

    func clearError() {
        errorMessage = nil
        refreshFailureMessage = nil
    }

    // MARK: - Control Panel

    /// Runs one read or one action of the data source. Returns `nil` and shows the error
    /// when it fails. A cancelled request shows no message. The extensions of `AppState`
    /// use it, so each action reports its failure in the same way.
    func run<Value>(
        _ action: (_ source: any RailwayDataSource, _ token: String) async throws -> Value
    ) async -> Value? {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return nil
        }

        errorMessage = nil

        do {
            return try await withAccessToken(action)
        } catch let error as RailwayError {
            show(error)
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Runs an action that Railway answers with `true` or `false`. A `false` answer shows
    /// `failure`.
    func runAction(
        failure: String,
        _ action: (_ source: any RailwayDataSource, _ token: String) async throws -> Bool
    ) async -> Bool {
        guard let didSucceed = await run(action) else { return false }
        if !didSucceed {
            errorMessage = failure
        }
        return didSucceed
    }

    // MARK: - Sign In

    /// Opens the Railway sign-in page, exchanges the code for tokens and loads the
    /// workspaces. A closed sign-in window shows no message.
    func signIn() async {
        guard let clientID = oauthClientID, !isSigningIn else { return }
        let request = AuthorizationRequest(clientID: clientID)
        sessionGeneration.record(.signInStarted)
        let generation = sessionGeneration
        let web = WebSignIn()
        webSignIn = web
        isSigningIn = true
        signInError = nil
        sessionNotice = nil
        defer {
            // A sign-out or sample data during the sign-in already reset these.
            if generation == sessionGeneration {
                isSigningIn = false
                webSignIn = nil
            }
        }

        do {
            let callback = try await web.callbackURL(for: request.url)
            // After each wait: a sign-out or sample data replaced this sign-in.
            guard generation == sessionGeneration else { return }
            let code = try AuthorizationCallback.code(in: callback, state: request.state)
            let newTokens = try await oauthClient.exchange(
                code: code, verifier: request.pkce.verifier, clientID: clientID)
            guard generation == sessionGeneration else { return }
            guard save(newTokens) else {
                reportSignInFailure("Topway cannot save the sign-in to the Keychain. Try again.")
                return
            }
            tokens = newTokens
            // A rejected token of the earlier sign-in no longer applies.
            clearError()
            // A sign-in replaces the sample data.
            exitSampleMode()
            let previousWorkspace = workspaceId
            await loadAccount()
            // The same workspace: its projects load again with the new sign-in.
            if generation == sessionGeneration, isConfigured, workspaceId == previousWorkspace {
                await loadProjects()
            }
        } catch let error as OAuthError {
            guard generation == sessionGeneration else { return }
            reportSignInFailure(error.errorDescription)
        } catch {
            guard generation == sessionGeneration else { return }
            reportSignInFailure(error.localizedDescription)
        }
    }

    /// Closes the sign-in window and drops the late results of the earlier sign-in and of
    /// its account loads.
    private func invalidateSession(_ event: SessionGeneration.Event) {
        sessionGeneration.record(event)
        webSignIn?.cancel()
        webSignIn = nil
        isSigningIn = false
    }

    /// The start screen shows the message. While an earlier sign-in stays, for example after
    /// **Sign in again**, the start screen does not show, so the open screen shows it.
    private func reportSignInFailure(_ message: String?) {
        guard let message else { return }
        if isSignedIn {
            errorMessage = message
        } else {
            signInError = message
        }
    }

    /// Loads the account and selects the workspace: the saved one when the account still has
    /// it, or the only one. With several, the user chooses.
    /// - Returns: The error message, or `nil` when the account loaded.
    @discardableResult
    func loadAccount() async -> String? {
        guard isSignedIn, !isSampleMode else { return nil }
        let generation = sessionGeneration
        do {
            let loaded = try await withAccessToken { _, token in
                try await accountClient.fetchAccount(token: token)
            }
            // A sign-out, a new sign-in or sample data during the request: the answer belongs
            // to an earlier session.
            guard generation == sessionGeneration else { return nil }
            account = loaded
            let selection = WorkspaceChoice.selection(saved: workspaceId, in: loaded.workspaces)
            if selection != workspaceId {
                selectWorkspace(selection ?? "")
            }
            return nil
        } catch let error as RailwayError {
            guard generation == sessionGeneration else { return nil }
            show(error)
            return errorMessage
        } catch {
            guard generation == sessionGeneration else { return nil }
            errorMessage = error.localizedDescription
            return errorMessage
        }
    }

    /// Shows the projects of a different workspace. An empty ID shows the workspace list.
    func selectWorkspace(_ id: String) {
        workspaceId = id
        latestProjectLoad += 1
        projects = []
        isLoading = false
        pendingConfirmation = nil
        clearError()
        restartAutoRefresh()
        guard isConfigured else { return }
        Task { await loadProjects() }
    }

    /// Removes the sign-in from this Mac. Railway has no revocation endpoint: the user removes
    /// the access of Topway on the Apps page of the Railway account settings.
    /// - Returns: `false` when the Keychain did not delete the tokens. The sign-in then stays.
    @discardableResult
    func signOut() -> Bool {
        guard KeychainStore.delete(Self.tokensKey) else { return false }
        endSession()
        return true
    }

    /// Shows the start screen with no sign-in. Sample mode stays on, because it does not use
    /// the token.
    private func endSession(notice: String? = nil) {
        invalidateSession(.signedOut)
        tokens = nil
        tokenRefresh?.cancel()
        tokenRefresh = nil
        account = nil
        sessionNotice = notice
        workspaceId = ""
        guard !isSampleMode else { return }
        latestProjectLoad += 1
        clearIncident()
        projects = []
        isLoading = false
        cancelRunningConfirmation()
        clearError()
        stopAutoRefresh()
    }

    /// Writes the tokens to the Keychain as one item.
    private func save(_ newTokens: OAuthTokens) -> Bool {
        guard let value = newTokens.keychainValue else { return false }
        return KeychainStore.save(value, for: Self.tokensKey)
    }

    /// Runs one request with an access token that is not expired. Sample mode has no token.
    ///
    /// When Railway does not accept the token, Topway refreshes it one time and sends the
    /// request again. Railway does not run a request that it does not accept, so the second
    /// request cannot repeat an action.
    /// - Parameter retryingRejected: `false` when a Not Authorized answer is about access
    ///   rights, so a new token cannot help.
    ///
    /// A sign-out, a new sign-in or sample data while the request waits makes its result
    /// `RailwayError.cancelled`: no message and no retry, so a late answer cannot send a
    /// request again with the token of a different account.
    private func withAccessToken<Value>(
        retryingRejected: Bool = true,
        _ request: (_ source: any RailwayDataSource, _ token: String) async throws -> Value
    ) async throws -> Value {
        let generation = sessionGeneration
        let source = dataSource
        guard !isSampleMode else { return try await request(source, "") }

        func checkSession() throws {
            guard generation == sessionGeneration else { throw RailwayError.cancelled }
        }
        /// Each result and each error of an earlier session is a cancellation.
        func inSession<Output>(_ step: () async throws -> Output) async throws -> Output {
            do {
                let result = try await step()
                try checkSession()
                return result
            } catch {
                try checkSession()
                throw error
            }
        }

        let token = try await inSession { try await accessToken() }
        do {
            return try await inSession { try await request(source, token) }
        } catch let error as RailwayError
            where retryingRejected
            && sessionGeneration.permitsRetry(of: error, startedIn: generation)
        {
            let renewed = try await inSession { try await refreshedTokens(replacing: token) }
            return try await inSession { try await request(source, renewed.accessToken) }
        }
    }

    /// The access token for the next request. A token that expires in less than 5 minutes is
    /// refreshed first.
    private func accessToken() async throws -> String {
        // A request that started before a sign-out shows no message.
        guard let current = tokens else { throw RailwayError.cancelled }
        guard current.needsRefresh(at: .now) else { return current.accessToken }
        do {
            return try await refreshedTokens(replacing: current.accessToken).accessToken
        } catch let error as OAuthError {
            // A network problem or a server error: the token works until it expires.
            guard current.expiresAt > .now else { throw error }
            return current.accessToken
        }
    }

    /// Gives the log stream a token at each connect and each poll.
    /// A stream that started before a sign-out gets no token of the next sign-in.
    private func logToken() -> @Sendable () async throws -> String {
        guard !isSampleMode else { return { "" } }
        let generation = sessionGeneration
        return { [weak self] in
            guard let self else { throw RailwayError.cancelled }
            return try await self.streamToken(startedIn: generation)
        }
    }

    private func streamToken(startedIn generation: SessionGeneration) async throws -> String {
        guard generation == sessionGeneration else { throw RailwayError.cancelled }
        // The token can wait for a refresh. A sign-in that completed meanwhile belongs to
        // another session, and the token or the error can belong to the earlier account.
        do {
            let token = try await accessToken()
            guard generation == sessionGeneration else { throw RailwayError.cancelled }
            return token
        } catch {
            guard generation == sessionGeneration else { throw RailwayError.cancelled }
            throw error
        }
    }

    /// Gets new tokens after `usedToken`. A request that comes during a refresh waits for it,
    /// and a request that comes after a refresh uses its tokens. When Railway does not accept
    /// the refresh token, the sign-in ends and the start screen shows. A network error keeps
    /// the sign-in.
    private func refreshedTokens(replacing usedToken: String) async throws -> OAuthTokens {
        if let tokenRefresh {
            return try await tokenRefresh.value
        }
        guard let current = tokens, let clientID = oauthClientID else {
            throw RailwayError.cancelled
        }
        if current.accessToken != usedToken, !current.needsRefresh(at: .now) {
            return current
        }

        let client = oauthClient
        let generation = sessionGeneration
        let refresh = Task {
            do {
                let renewed = try await client.refresh(current, clientID: clientID)
                // A sign-out or a completed new sign-in replaced these tokens. While the tokens
                // stay, the new ones are kept also when **Sign in again** started: Railway can
                // rotate the refresh token, and a use of the earlier one ends the authorization.
                guard tokens == current else { throw RailwayError.cancelled }
                tokens = renewed
                sessionGeneration.record(.tokensRefreshed)
                // A failed write keeps the new tokens for this session. At the next launch,
                // Railway does not accept the earlier refresh token, and the user signs in.
                _ = save(renewed)
                return renewed
            } catch let error as OAuthError {
                // A refusal of an earlier session ends nothing: it must not close the window
                // of a newer sign-in. The next request of this session refreshes again.
                if tokens == current,
                    sessionGeneration.permitsSessionEnd(after: error, startedIn: generation)
                {
                    KeychainStore.delete(Self.tokensKey)
                    endSession(
                        notice: "Your Railway sign-in ended. Sign in again to see your projects.")
                }
                guard error == .rejected || error == .cancelled else { throw error }
                throw RailwayError.cancelled
            }
        }
        tokenRefresh = refresh
        defer {
            if tokenRefresh == refresh {
                tokenRefresh = nil
            }
        }
        return try await refresh.value
    }

    // MARK: - Sample Mode

    func enterSampleMode() {
        invalidateSession(.sampleModeStarted)
        // An earlier sign-in message must not show when sample mode ends.
        signInError = nil
        sessionNotice = nil
        switchDataSource(to: SampleDataSource(), isSampleMode: true)
    }

    func exitSampleMode() {
        guard isSampleMode else { return }
        switchDataSource(to: RailwayClient(), isSampleMode: false)
    }

    /// Removes the projects of the earlier data source. `MainView` then loads the new projects.
    private func switchDataSource(to source: any RailwayDataSource, isSampleMode: Bool) {
        dataSource = source
        latestProjectLoad += 1
        alertSnapshot = nil
        clearIncident()
        self.isSampleMode = isSampleMode
        projects = []
        isLoading = false
        pendingConfirmation = nil
        clearError()
        restartAutoRefresh()
    }

    // MARK: - Incident

    /// Asks Railway for its platform status, at most one time in 5 minutes. The request has
    /// no token. Sample mode sends no request and shows a sample incident. A failed check
    /// keeps the last answer, because a network problem does not end an incident.
    private func checkIncident() async {
        guard IncidentCheck.isDue(lastCheck: lastIncidentCheck, now: .now) else { return }
        lastIncidentCheck = .now
        let generation = incidentGeneration
        do {
            let found = try await dataSource.fetchOpenIncident()
            // An answer of the earlier data source must not show for the new one.
            guard generation == incidentGeneration else { return }
            incident = found
        } catch {
            // The banner is extra information, so a failed check shows no error.
        }
    }

    /// Runs when the menu bar window opens. With auto refresh off, no project load runs
    /// then, and the banner must not show an old answer. `checkIncident()` keeps the limit
    /// of one request in 5 minutes.
    func refreshIncident() async {
        guard isConfigured else { return }
        await checkIncident()
    }

    func hideIncident() {
        hiddenIncidentId = incident?.id
    }

    /// `true` one time for each incident, so VoiceOver does not say the same incident each
    /// time the menu bar window opens.
    func shouldAnnounceIncident(id: String) -> Bool {
        guard announcedIncidentId != id else { return false }
        announcedIncidentId = id
        return true
    }

    private func clearIncident() {
        incidentGeneration += 1
        incident = nil
        lastIncidentCheck = nil
        hiddenIncidentId = nil
        announcedIncidentId = nil
    }

    // MARK: - Alerts

    func toggleMute(projectId: String) {
        if mutedProjectIds.contains(projectId) {
            mutedProjectIds.remove(projectId)
        } else {
            mutedProjectIds.insert(projectId)
        }
    }

    /// Compares the new statuses with the earlier load and sends the alerts.
    /// The snapshot changes also when alerts are off, so turning them on gives no old alerts.
    private func sendAlerts(for projects: [Project]) {
        let statuses = projects.flatMap(\.serviceStatuses)
        guard var snapshot = alertSnapshot else {
            alertSnapshot = AlertSnapshot(statuses: statuses)
            return
        }
        let alerts = snapshot.update(with: statuses, mutedProjectIds: mutedProjectIds)
        alertSnapshot = snapshot
        guard alertsEnabled, !alerts.isEmpty else { return }
        let isSampleMode = isSampleMode
        Task {
            do {
                try await AlertNotifier.send(alerts, isSampleMode: isSampleMode)
            } catch {
                errorMessage = "Topway cannot show an alert. \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Confirmation

    /// Runs the action at once for low harm. Other levels wait for the user in the dialog.
    func confirm(_ request: ConfirmationRequest) {
        guard request.harm.needsDialog else {
            Task { await request.perform() }
            return
        }
        pendingConfirmation = request
    }

    func cancelConfirmation() {
        guard !isRunningConfirmation else { return }
        pendingConfirmation = nil
    }

    /// Keeps the dialog open with a progress indicator until the action ends.
    func runPendingConfirmation() {
        guard let request = pendingConfirmation, !isRunningConfirmation else { return }
        isRunningConfirmation = true
        confirmationTask = Task {
            await request.perform()
            // A sign-out closed the dialog, and a new dialog can show now.
            guard !Task.isCancelled else { return }
            isRunningConfirmation = false
            pendingConfirmation = nil
            confirmationTask = nil
        }
    }

    /// Stops the action of the dialog and closes it. The action belongs to the earlier sign-in.
    private func cancelRunningConfirmation() {
        confirmationTask?.cancel()
        confirmationTask = nil
        isRunningConfirmation = false
        pendingConfirmation = nil
    }

    // MARK: - Variable Management

    func upsertVariable(
        projectId: String, environmentId: String, serviceId: String, name: String, value: String
    ) async -> Bool {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return false
        }

        errorMessage = nil

        do {
            let success = try await withAccessToken { source, token in
                try await source.upsertVariable(
                    projectId: projectId,
                    environmentId: environmentId,
                    serviceId: serviceId,
                    name: name,
                    value: value,
                    token: token
                )
            }
            if !success {
                errorMessage = "Railway did not save the variable. Try again."
            }
            return success
        } catch let error as RailwayError {
            show(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteVariable(projectId: String, environmentId: String, serviceId: String, name: String)
        async -> Bool
    {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return false
        }

        errorMessage = nil

        do {
            let success = try await withAccessToken { source, token in
                try await source.deleteVariable(
                    projectId: projectId,
                    environmentId: environmentId,
                    serviceId: serviceId,
                    name: name,
                    token: token
                )
            }
            if !success {
                errorMessage = "Railway did not delete the variable. Try again."
            }
            return success
        } catch let error as RailwayError {
            show(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Service Management

    func deleteService(serviceId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let success = try await withAccessToken { source, token in
                try await source.deleteService(
                    serviceId: serviceId,
                    token: token
                )
            }
            if success {
                await loadProjects()
            } else {
                errorMessage = "Railway did not delete the service. Try again."
                isLoading = false
            }
            return success
        } catch let error as RailwayError {
            show(error)
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Deployment Management

    func fetchDeployments(projectId: String, environmentId: String, serviceId: String) async
        -> [Deployment]?
    {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return nil
        }

        errorMessage = nil

        do {
            let deployments = try await withAccessToken { source, token in
                try await source.fetchDeployments(
                    projectId: projectId,
                    environmentId: environmentId,
                    serviceId: serviceId,
                    token: token
                )
            }
            return deployments
        } catch let error as RailwayError {
            show(error)
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func restartDeployment(deploymentId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return false
        }

        errorMessage = nil

        do {
            let success = try await withAccessToken { source, token in
                try await source.restartDeployment(
                    deploymentId: deploymentId,
                    token: token
                )
            }
            if !success {
                errorMessage = "Railway did not restart the deployment. Try again."
            }
            return success
        } catch let error as RailwayError {
            show(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func redeployService(environmentId: String, serviceId: String) async -> Bool {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return false
        }

        errorMessage = nil

        do {
            let success = try await withAccessToken { source, token in
                try await source.redeployService(
                    environmentId: environmentId,
                    serviceId: serviceId,
                    token: token
                )
            }
            if !success {
                errorMessage = "Railway did not start the redeploy. Try again."
            }
            return success
        } catch let error as RailwayError {
            show(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Metrics

    /// Returns `nil` when the fetch fails or is cancelled. A cancelled load, or a load that a
    /// newer load replaced, shows no error, so an earlier failure cannot show over new charts.
    func fetchMetrics(environmentId: String, serviceId: String, window: MetricWindow) async
        -> ServiceMetrics?
    {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return nil
        }

        errorMessage = nil

        latestMetricsLoad += 1
        let load = latestMetricsLoad
        do {
            return try await withAccessToken { source, token in
                try await source.fetchMetrics(
                    environmentId: environmentId,
                    serviceId: serviceId,
                    window: window,
                    token: token
                )
            }
        } catch let error as RailwayError {
            guard load == latestMetricsLoad, !Task.isCancelled else { return nil }
            show(error)
            return nil
        } catch {
            guard load == latestMetricsLoad, !Task.isCancelled else { return nil }
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Spend

    /// Returns `nil` when the fetch fails or is cancelled.
    func fetchSpend() async -> Spend? {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return nil
        }

        errorMessage = nil
        latestSpendLoad += 1
        let load = latestSpendLoad
        let requestedWorkspaceId = workspaceId

        // A newer load, a cancelled load or a different workspace publishes no error.
        func isCurrent() -> Bool {
            load == latestSpendLoad && !Task.isCancelled && workspaceId == requestedWorkspaceId
        }

        do {
            // A Not Authorized answer here is about billing access, so a new token cannot help.
            let spend = try await withAccessToken(retryingRejected: false) { source, token in
                try await source.fetchSpend(workspaceId: requestedWorkspaceId, token: token)
            }
            return isCurrent() ? spend : nil
        } catch let error as RailwayError {
            // Not `show(_:)`: a Not Authorized answer here is about billing access, and the
            // token is not rejected. A cancelled load has no message.
            if isCurrent(), let message = Spend.failureMessage(for: error) {
                errorMessage = message
            }
            return nil
        } catch {
            if isCurrent() {
                errorMessage = error.localizedDescription
            }
            return nil
        }
    }

    // MARK: - Logs

    /// Gives each log event to `onEvent` until the stream ends or the task is cancelled.
    /// Returns `true` when the stream ended with no error. Sets `errorMessage` when it fails.
    func streamLogs(_ kind: LogKind, deploymentId: String, onEvent: (LogEvent) -> Void) async
        -> Bool
    {
        guard isConfigured else {
            errorMessage = Self.notConnectedMessage
            return false
        }

        errorMessage = nil

        do {
            // The stream asks for the token at each connect and each poll, so a reconnect after
            // a refresh sends the new token.
            for try await event in dataSource.logs(
                kind, deploymentId: deploymentId, token: logToken())
            {
                // An event of a cancelled stream must not reach the next tab.
                guard !Task.isCancelled else { break }
                onEvent(event)
            }
            return true
        } catch let error as RailwayError {
            show(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        guard autoRefreshEnabled && isConfigured else { return }

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.autoRefreshInterval ?? 30))
                guard !Task.isCancelled else { break }
                // A background refresh must not remove the error of a failed action.
                await self?.loadProjects(keepingError: true)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func restartAutoRefresh() {
        stopAutoRefresh()
        startAutoRefresh()
    }

    /// Runs at app launch. Loads the projects once, so the menu bar shows the health at once.
    func initializeAutoRefresh() async {
        guard isConfigured else { return }
        startAutoRefresh()
        await loadProjects()
    }
}
