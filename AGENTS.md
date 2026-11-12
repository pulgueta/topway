# AGENTS.md

## Overview

Topway is a native **macOS menu bar app** (SwiftUI) for monitoring and managing Railway projects, services, environment variables, and deployments — a lightweight alternative to keeping the Railway dashboard open. It talks directly to Railway's public GraphQL API.

## Build & Run

The app is an Xcode project with one local package, `Packages/TopwayCore`. There are no third-party packages. Open `topway.xcodeproj` in Xcode and run (scheme `topway`), or from the CLI:

```sh
# Build (with no signing; signing needs the certificate of team 7QNFW3929Z)
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug CODE_SIGNING_ALLOWED=NO build

# Build into a known location, then launch
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug \
  CODE_SIGNING_ALLOWED=NO -derivedDataPath build build
open build/Build/Products/Debug/topway.app

# Test the core
swift test --package-path Packages/TopwayCore

# Format and lint
swift format --in-place --recursive topway Packages
swift format lint --recursive --strict topway Packages
```

- **Deployment target: macOS 26.2** (Tahoe). The UI uses Liquid Glass APIs like `.buttonStyle(.glassProminent)` that require the macOS 26 SDK — older Xcode/SDKs will not compile.
- **Swift 6** with strict concurrency and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`: every type in the app target is `@MainActor`-isolated unless explicitly marked otherwise. `TopwayCore` has no default isolation and uses `Sendable` types.
- The app is **sandboxed** (`topway/topway.entitlements`) with hardened runtime; only `network.client` is granted.

## Architecture

The app is built around a single observable state object injected through the SwiftUI environment.

- **`AppState`** (`@MainActor @Observable`) — the single source of truth. Holds `projects`, `isLoading`, `errorMessage`, credentials, and the auto-refresh task. Every user action goes through one of its `async` methods, which call its `RailwayDataSource` (`RailwayClient`, or `SampleDataSource` in sample mode), then convert thrown `RailwayError`s into `errorMessage` strings (the client throws; AppState never re-throws to the view). Most write methods call `loadProjects()` afterward to reconcile UI with the server. Injected via `.environment(appState)` in `topway/App/TopwayApp.swift` and read with `@Environment(AppState.self)`.

- **`RailwayClient`** (`Sendable` struct in `TopwayCore`) — stateless GraphQL transport against `https://backboard.railway.com/graphql/v2`. Every call is a `POST` with a `Bearer` token. All operations funnel through the private `execute` generic, which throws typed `RailwayError`s for HTTP and GraphQL failures. A cancelled request is `RailwayError.cancelled` and shows no message. **User input is always passed as GraphQL `variables`, never string-interpolated into the query** — this is intentional (injection/escaping safety); preserve it when adding operations.

- **Logs** use WebSockets, with polling as the fallback. `GraphQLWebSocket` sends one `graphql-transport-ws` subscription to `wss://backboard.railway.com/graphql/v2`; Railway reads the token from the `Authorization: Bearer` header of the upgrade request, and `connection_init` has no payload. The protocol rules are pure code in `GraphQLSubscription` (tested without a network). `SocketKeepalive` sends a protocol `ping` every 20 s and drops a socket with no message for 20 s after a ping (Railway sends no pings of its own). `LogRecovery` (pure, tested) decides each step: after a live socket drops it connects again with a backoff (2, 4, 8, 16, then 30 s; a payload resets it; after 5 reconnects in a row that do not connect, it polls), after 3 live passes with no payload it polls (network error) or stops (bad data), it polls when the socket never connected, and it stops on a Railway error. Polling sends one `deploymentLogs`/`buildLogs` request each 5 s, keeps going after a network error, tries the socket again every 60 s, and ends a build log when the deployment status shows the build is finished. `GraphQLWebSocket` moves frames through `MessageTransport`, so tests use `ScriptedTransport` and `ScriptedConnector`. `LogDeduplicator` removes repeated lines (same timestamp, message and severity, in the last 1,000 lines). `RailwayClient` and `SampleDataSource` take a `sleep` closure, so tests do not wait. `LogsView` keeps the newest 1,000 lines in `LogBuffer` and stops the stream when it closes. When you add a subscription, use the WebSocket first and check the document on the public endpoint with no token: a valid document answers "Not Authorized", "not found" or "Problem processing request", and a wrong document answers "Cannot query field".

- **Metrics** come from the Railway `metrics` query (`RailwayDataSource.fetchMetrics`): `CPU_USAGE` (vCPU), `MEMORY_USAGE_GB`, `NETWORK_RX_GB` and `NETWORK_TX_GB` for one service in one environment. `MetricWindow` gives the start date and `sampleRateSeconds` (30, 60 or 240, as the Railway CLI does). `ServiceMetrics` (pure, tested) gives one `MetricSeries` for each `MetricKind` and adds the results of one measurement at each time. `MetricKind.formatted` gives the text of a value. `MetricsView` loads on open, on a new time range and on **Refresh**; it does not poll. `MetricCard` draws the chart with Swift Charts (a system framework). `SampleDataSource+Metrics` gives a wave that comes only from the service, the environment and the date.

- **Spend** (`RailwayDataSource.fetchSpend`, `TopwayCore/Spend`) is for the workspace. `RailwayClient` sends two requests: `workspace.customer` gives `currentUsage` (the cost in US dollars, which Railway calculates and keeps in a cache), `billingPeriod` and `usageLimit` (whole US dollars; a `softLimit` of 0 is not set); then `usage` gives the totals of `UsageKind` from the period start to now (vCPU-minutes, GB-minutes, GB). **Topway has no price table and calculates no cost.** Do not add prices: show only a cost that Railway gives. `Spend` (pure, tested) has the days left, the limit use and the dollar text. `SpendRow` in the projects list opens `SpendView`.

- **`TopwayCore/Models` and `TopwayCore/API/Responses`** — one type in each file. `Decodable` structs mirroring Railway's Relay-style `edges`/`node` connection shape, one `*Data` wrapper per query/mutation, plus UI models (`EnvironmentVariable`, computed display helpers on `Deployment`). Convenience extensions (`Project.serviceList`, `Workspace.projectList`) flatten connections for the views.

- **Navigation** — there is **no `NavigationStack`**. `MainView` holds a `NavigationDestination` enum and switches between `.main` / `.usage` / `.addService` / `.service` with animated transitions inside a fixed **360×480** popover (`Layout`). `ServiceView` has its own steps (`ServiceDestination`: `.overview` / `.editVariable` / `.logs`), and its overview has the tabs `ServiceTab.variables`, `.deployments` and `.metrics`. Escape (`onExitCommand`) navigates back one step.

- **Design** — read `DESIGN.md` before you change a screen. The rules that matter most: every action has a text label, and no action shows only on hover; the only icon-only buttons are back and close, with an accessibility label and `.help`; each screen uses `ScreenLayout` with `ScreenHeader` (top) and `ActionBar` (bottom); Liquid Glass is only on the control layer (`.buttonStyle(.glass)` / `.glassProminent` in the bars, inside one `GlassEffectContainer` per bar), never on a list row; lists use `LazyVStack`; sizes come from `Layout`; UI copy is ASD-STE100 Simplified Technical English.

- **Accessibility** — `docs/accessibility.md` has the evaluation for the App Store Accessibility Nutrition Labels and the manual checks. Keep these rules when you change a screen: a button that shows in each row names its item in the accessibility label, and `accessibilityInputLabels` gives Voice Control the visible text; a status is never color only; each custom animation and transition reads `accessibilityReduceMotion`; an error that shows away from the control posts an `AccessibilityNotification.Announcement`; the dialog hides the content behind it (`destructiveConfirmation`). Pure wording for a label, such as `HealthSummary.statusDescription`, goes in `TopwayCore` with tests.

### Key conventions & gotchas

- **Credentials storage is split**: the API token lives in the **Keychain** via `KeychainStore` (in `TopwayCore`) (never UserDefaults); `workspaceId`, auto-refresh, alert and mute prefs live in `UserDefaults`. `AppState.init` migrates any legacy cleartext token out of UserDefaults into the Keychain. `AppState.railwayToken` reads an in-memory mirror (`tokenStorage`) to keep the Keychain off the hot path; writes go through `updateToken`, which returns success so the UI can surface a save failure. `removeToken()` deletes the token (Settings > Credentials > **Remove token…**); the app then shows the start screen.

- **A rejected token must never trap the user.** Railway answers a bad token with HTTP 200 and the GraphQL error "Not Authorized"; `RailwayError.init(graphQLErrors:)` turns that message (and an HTTP 401) into `.unauthorized`. `AppState.isTokenRejected` is `true` while `errorMessage` comes from that error. `ErrorStateView` gets its buttons from `RecoveryRules` in `TopwayCore` (tested): a rejected token offers **Open Settings** and **Try with sample data**; other failures offer **Try again** and **Open Settings**; sample mode offers only **Try again**.

- **Pass closure literals to SwiftUI APIs**, for example `Button("Save") { save() }` and `set: { setValue($0) }`. Xcode 26.6 on CI crashes when a main-actor method reference is passed as a `Button` action or a `Binding` setter.

- **Confirmations use `GlassConfirmationDialog` through `destructiveConfirmation(...)`, never `alert`/`confirmationDialog`.** Call `appState.confirm` with a `ConfirmationRequest`, and set its `HarmLevel` (low: no dialog; medium: names the service and environment; high: exact name typed). `MainView` presents the dialog. Native dialogs present in a separate window and steal key focus, which dismisses the `MenuBarExtra(.window)` popover out from under them. Keep all confirmation UI within the popover.

- **Railway API limitations** (reflected in the UI): project _creation_ isn't available on the public API — the app deep-links to the Railway dashboard instead. Service creation is GitHub-repo or Docker-image only. Soft-deleted projects keep coming back from the API with a `deletedAt` set; they're filtered out in `Workspace.projectList`.

- **Auto-refresh** is a single cancellable `Task` loop in `AppState` (`startAutoRefresh`/`stopAutoRefresh`/`restartAutoRefresh`). Toggling the setting or interval restarts it. `initializeAutoRefresh()` runs from the `.task` of the `MenuBarExtra` label (`MenuBarLabel`). The label shows at launch, so the refresh starts at launch, not when the popover opens. It also loads the projects once.

- **Health and alerts** are pure logic in `TopwayCore/Health`. `HealthSummary(projects:)` gives the menu bar health. `AlertSnapshot` keeps the last settled state (deployment ID and status) of each service; in-progress statuses do not replace it. `AlertSnapshot.update(with:mutedProjectIds:)` gives the alerts of a new load. `AppState.sendAlerts(for:)` runs after each successful `loadProjects()` and keeps the snapshot (`alertSnapshot`). Set `alertSnapshot = nil` when the data source or the workspace changes; a `nil` snapshot gives no alerts. `AlertNotifier` sends `UNUserNotificationCenter` notifications; in sample mode the subtitle is "Sample data". `NotificationPresenter` (set in `TopwayApp.init`) shows banners while the app is active; the center keeps a weak reference, so `TopwayApp` keeps it. `alertsEnabled` and `mutedProjectIds` live in `UserDefaults`. Settings asks for notification permission only when the user turns alerts on. Launch at login uses `SMAppService.mainApp` in `LaunchAtLoginToggle`, which reads the system state and keeps no copy.

- **Problem reports go through GitHub Issues only.** The app collects no data and has no crash SDK. **Settings > Help** (`HelpSettingsSection`) opens the link from `IssueReportLink` (`TopwayCore/Reports`, tested), which fills the device fields of a form in `.github/ISSUE_TEMPLATE` from `DeviceDetails`. The query item names are the field ids of the forms, so change them together. GitHub fills only text fields from a link, so the device fields are `input` fields, not dropdowns. Never add a token, a Workspace ID or project data to the link.
