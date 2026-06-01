# AGENTS.md

## Overview

Topway is a native **macOS menu bar app** (SwiftUI) for monitoring and managing Railway projects, services, environment variables, and deployments — a lightweight alternative to keeping the Railway dashboard open. It talks directly to Railway's public GraphQL API.

## Build & Run

There is no package manager, no test target, and no lint config — it's a plain Xcode project. Open `topway.xcodeproj` in Xcode and run (scheme `topway`), or from the CLI:

```sh
# Build
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug build

# Build into a known location, then launch
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug \
  -derivedDataPath build build
open build/Build/Products/Debug/topway.app
```

- **Deployment target: macOS 26.2** (Tahoe). The UI uses Liquid Glass APIs like `.buttonStyle(.glassProminent)` that require the macOS 26 SDK — older Xcode/SDKs will not compile.
- **Swift 6** with strict concurrency and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`: every type is `@MainActor`-isolated unless explicitly marked otherwise (see `KeychainStore`'s `nonisolated` statics).
- The app is **sandboxed** (`topway/topway.entitlements`) with hardened runtime; only `network.client` is granted.

## Architecture

The app is built around a single observable state object injected through the SwiftUI environment.

- **`AppState`** (`@MainActor @Observable`) — the single source of truth. Holds `projects`, `isLoading`, `errorMessage`, credentials, and the auto-refresh task. Every user action goes through one of its `async` methods, which call `RailwayClient`, then convert thrown `RailwayError`s into `errorMessage` strings (the client throws; AppState never re-throws to the view). Most write methods call `loadProjects()` afterward to reconcile UI with the server. Injected via `.environment(appState)` in `topwayApp.swift` and read with `@Environment(AppState.self)`.

- **`RailwayClient`** (`@MainActor`) — stateless GraphQL transport against `https://backboard.railway.com/graphql/v2`. Every call is a `POST` with a `Bearer` token. All operations funnel through the private `executeQuery` generic, which decodes into `GraphQLResponse<T>`. **User input is always passed as GraphQL `variables`, never string-interpolated into the query** — this is intentional (injection/escaping safety); preserve it when adding operations.

- **`Models.swift`** — `Decodable` structs mirroring Railway's Relay-style `edges`/`node` connection shape, one `*Data` wrapper per query/mutation, plus UI models (`EnvironmentVariable`, computed display helpers on `Deployment`). Convenience extensions (`Project.serviceList`, `Workspace.projectList`) flatten connections for the views.

- **Navigation** — there is **no `NavigationStack`**. `MainView` holds a `NavigationDestination` enum and switches between `.main` / `.addService` / `.variables` with animated transitions inside a fixed **320×400** popover. Escape (`onExitCommand`) navigates back.

### Key conventions & gotchas

- **Credentials storage is split**: the API token lives in the **Keychain** via `KeychainStore` (never UserDefaults); `workspaceId` and auto-refresh prefs live in `UserDefaults`. `AppState.init` migrates any legacy cleartext token out of UserDefaults into the Keychain. `AppState.railwayToken` reads an in-memory mirror (`tokenStorage`) to keep the Keychain off the hot path; writes go through `updateToken`, which returns success so the UI can surface a save failure.

- **Destructive confirmations use the custom `InlineConfirmation` view, never `alert`/`confirmationDialog`.** Native dialogs present in a separate window and steal key focus, which dismisses the `MenuBarExtra(.window)` popover out from under them. Keep all confirmation UI inline within the popover.

- **Railway API limitations** (reflected in the UI): project _creation_ isn't available on the public API — the app deep-links to the Railway dashboard instead. Service creation is GitHub-repo or Docker-image only. Soft-deleted projects keep coming back from the API with a `deletedAt` set; they're filtered out in `Workspace.projectList`.

- **Auto-refresh** is a single cancellable `Task` loop in `AppState` (`startAutoRefresh`/`stopAutoRefresh`/`restartAutoRefresh`). Toggling the setting or interval restarts it; `initializeAutoRefresh()` is kicked off from the `MenuBarExtra` `.task`.
