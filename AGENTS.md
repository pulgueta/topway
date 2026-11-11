# AGENTS.md

## Overview

Topway is a native **macOS menu bar app** (SwiftUI) for monitoring and managing Railway projects, services, environment variables, and deployments — a lightweight alternative to keeping the Railway dashboard open. It talks directly to Railway's public GraphQL API.

## Build & Run

The app is an Xcode project with one local package, `Packages/TopwayCore`. There are no third-party packages. Open `topway.xcodeproj` in Xcode and run (scheme `topway`), or from the CLI:

```sh
# Build
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug build

# Build into a known location, then launch
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug \
  -derivedDataPath build build
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

- **`TopwayCore/Models` and `TopwayCore/API/Responses`** — one type in each file. `Decodable` structs mirroring Railway's Relay-style `edges`/`node` connection shape, one `*Data` wrapper per query/mutation, plus UI models (`EnvironmentVariable`, computed display helpers on `Deployment`). Convenience extensions (`Project.serviceList`, `Workspace.projectList`) flatten connections for the views.

- **Navigation** — there is **no `NavigationStack`**. `MainView` holds a `NavigationDestination` enum and switches between `.main` / `.addService` / `.variables` with animated transitions inside a fixed **320×400** popover. Escape (`onExitCommand`) navigates back.

### Key conventions & gotchas

- **Credentials storage is split**: the API token lives in the **Keychain** via `KeychainStore` (in `TopwayCore`) (never UserDefaults); `workspaceId`, auto-refresh, alert and mute prefs live in `UserDefaults`. `AppState.init` migrates any legacy cleartext token out of UserDefaults into the Keychain. `AppState.railwayToken` reads an in-memory mirror (`tokenStorage`) to keep the Keychain off the hot path; writes go through `updateToken`, which returns success so the UI can surface a save failure.

- **Confirmations use `GlassConfirmationDialog` through `destructiveConfirmation(...)`, never `alert`/`confirmationDialog`.** Call `appState.confirm` with a `ConfirmationRequest`, and set its `HarmLevel` (low: no dialog; medium: names the service and environment; high: exact name typed). `MainView` presents the dialog. Native dialogs present in a separate window and steal key focus, which dismisses the `MenuBarExtra(.window)` popover out from under them. Keep all confirmation UI within the popover.

- **Railway API limitations** (reflected in the UI): project _creation_ isn't available on the public API — the app deep-links to the Railway dashboard instead. Service creation is GitHub-repo or Docker-image only. Soft-deleted projects keep coming back from the API with a `deletedAt` set; they're filtered out in `Workspace.projectList`.

- **Auto-refresh** is a single cancellable `Task` loop in `AppState` (`startAutoRefresh`/`stopAutoRefresh`/`restartAutoRefresh`). Toggling the setting or interval restarts it. `initializeAutoRefresh()` runs from the `.task` of the `MenuBarExtra` label (`MenuBarLabel`). The label shows at launch, so the refresh starts at launch, not when the popover opens. It also loads the projects once.

- **Health and alerts** are pure logic in `TopwayCore/Health`. `HealthSummary(projects:)` gives the menu bar health. `AlertRules.alerts(from:to:mutedProjectIds:)` compares the statuses of the earlier and the new load. `AppState.sendAlerts(for:)` runs after each successful `loadProjects()` and keeps the snapshot (`alertSnapshot`). Set `alertSnapshot = nil` when the data source or the workspace changes; a `nil` snapshot gives no alerts. `AlertNotifier` sends `UNUserNotificationCenter` notifications; in sample mode the subtitle is "Sample data". `alertsEnabled` and `mutedProjectIds` live in `UserDefaults`. Settings asks for notification permission only when the user turns alerts on. Launch at login uses `SMAppService.mainApp` in `LaunchAtLoginToggle`, which reads the system state and keeps no copy.
