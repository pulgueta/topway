# AGENTS.md

This file is for coding agents and for people who change Topway. It lists the rules and the gotchas that keep the app working. [ARCHITECTURE.md](ARCHITECTURE.md) explains the code, [DESIGN.md](DESIGN.md) has the screen rules, and [CONTRIBUTING.md](CONTRIBUTING.md) has the code rules.

Topway is a native macOS menu bar app (SwiftUI) that talks directly to the Railway public GraphQL API. The Xcode project has one local package, `Packages/TopwayCore`, and no third-party packages.

## Commands

```sh
# Build (with no signing; signing needs the certificate of team 7QNFW3929Z)
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug CODE_SIGNING_ALLOWED=NO build

# Build into a known location, then launch
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug \
  CODE_SIGNING_ALLOWED=NO -derivedDataPath build build
open build/Build/Products/Debug/topway.app

# Test the core (Swift Testing; run it here, not in Xcode)
swift test --package-path Packages/TopwayCore

# Format and lint
swift format --in-place --recursive topway Packages
swift format lint --recursive --strict topway Packages
```

Commits use `type(scope): brief description`, with no body. The types are `feat`, `fix`, `refactor`, `chore`, `docs`, `style` and `test`. Each commit has one purpose and must build.

## Platform

- The deployment target is macOS 26.2. The Liquid Glass APIs, such as `.buttonStyle(.glassProminent)`, need the macOS 26 SDK, so an older Xcode does not compile the app.
- Swift 6 with strict concurrency and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`: each type in the app target is `@MainActor` unless it says otherwise. `TopwayCore` has no default isolation and uses `Sendable` types.
- The app is sandboxed (`topway/topway.entitlements`), with hardened runtime and only the `network.client` entitlement.
- Pass closure literals to SwiftUI APIs, for example `Button("Save") { save() }` and `set: { setValue($0) }`. Xcode 26.6 on CI crashes when a main-actor method reference is a `Button` action or a `Binding` setter.

## OAuth client ID

- Put `RAILWAY_OAUTH_CLIENT_ID = <id>` in `Config/OAuth.local.xcconfig`, which Git ignores. **Never commit `Config/OAuth.local.xcconfig` or a client ID**, and never put the ID in `Config/OAuth.xcconfig` (committed, with an empty value). [README.md](README.md#build-from-source) tells how to make a Native OAuth app.
- With no value (CI, a build from source), the app builds and offers only sample data. To build with no client ID while the local file exists, add `RAILWAY_OAUTH_CLIENT_ID=` to the `xcodebuild` command.
- `Config/OAuth.xcconfig` includes the local file and is the base configuration of the app target. `topway/Info.plist` has `RailwayOAuthClientID = $(RAILWAY_OAUTH_CLIENT_ID)`. It merges with the generated Info.plist, and it is a membership exception of the synchronized folder.
- `RailwayOAuth.clientID(fromInfoValue:)` gives `nil` for an empty or not expanded value. Then `AppState.canSignIn` is `false`, and Topway does not read the saved sign-in.

## Sign-in callback

Keep these items in place, or the sign-in stops:

- The file `https://topway.pulgueta.com/.well-known/apple-app-site-association`. It names `7QNFW3929Z.com.pulgueta.topway` in `webcredentials`, and the server sends it as `application/json` with no redirect.
- The redirect URI `https://topway.pulgueta.com/oauth/callback` in the Railway OAuth app.
- The Associated Domains capability on the App ID, and `webcredentials:topway.pulgueta.com` in `topway/topway.entitlements`.

Associated Domains give the redirect only to an app of team 7QNFW3929Z. Topway registers no URL scheme and runs no local server. This closes the custom-scheme risk (RFC 8252, section 8.6) only when the Railway OAuth app has no other redirect URI, so **remove `topway://oauth/callback` from the Railway OAuth app before the App Store release**.

## Sign in with Railway

Sign in with Railway is the only way to connect. There is no API token field and no Workspace ID field. The pure rules are in `TopwayCore/OAuth` (tested), and the app part is in `topway/SignIn`. [ARCHITECTURE.md](ARCHITECTURE.md#sign-in-with-railway) has the flow.

- Never send a client secret. Railway refuses a Native app that sends one.
- The scopes are `openid email profile offline_access workspace:admin` (`RailwayOAuth.scopes`), with `prompt=consent`. Railway gives a refresh token only with `prompt=consent`. Without `email` and `profile`, `me { workspaces }` is empty, and it has only the workspaces that the user selected on the consent page.
- `workspace:admin` is a maximum: Railway gives the role that the user has in each selected workspace. Topway deletes services and projects and reads billing, and only an admin can do that.
- `FormEncoding` encodes all values, also `+`.
- `AuthorizationCallback.code(in:state:)` checks the address, the state (also on an error), the `iss` value when it is there, and the code.
- The session is not ephemeral, so a user who is signed in to Railway in the browser sees only the consent page. A closed window is `OAuthError.cancelled` and shows no message.
- Token answers:

  | Answer | Result |
  |---|---|
  | 400 or 401 with `invalid_grant` (RFC 6749, 5.2) | `OAuthError.rejected`: the tokens are deleted, and the user signs in again. |
  | Another code, such as `invalid_client` | `requestRefused(code)`: the tokens stay, and the message gives the code. |
  | 429 or 5xx | `serverError`: the sign-in stays. |

- Never show the body of a token answer, only the code. Never log a token, and never put one in a URL.
- `OAuthTokens` is one Keychain item (`railwayOAuth`, JSON), so the two tokens change together. If the Keychain does not save renewed tokens after two writes, the tokens stay in memory, and `errorMessage` says that the next launch can need a new sign-in.
- Only one refresh runs at a time (`tokenRefresh`). Railway rotates refresh tokens, and a use of a rotated refresh token ends the whole authorization. When a refresh fails with a network error before the token expires, the request uses the current token.
- `SessionGeneration` (tested) stops late answers from crossing sessions:
  - A request from an earlier generation ends as `RailwayError.cancelled`, with no message and no retry (`permitsRetry`). It never sends a request again with the token of another account.
  - A refused refresh ends the sign-in only in the session where it started (`permitsSessionEnd`), so it does not close the window of **Sign in again**.
  - A refresh that succeeds while the same tokens stay is kept, also after **Sign in again** starts, because Railway can rotate the refresh token.
  - `endSession` stops a running confirmation action and closes the dialog. A log stream gets no token of a later session.
- Railway has no revocation endpoint (`/oauth/token/revocation` answers 404). **Sign out…** removes the Keychain item and the workspace choice, and its footer sends the user to the Apps page of the Railway account settings.

## AppState.init deletes data

`AppState.init` deletes the API token of earlier builds (the Keychain item and the `UserDefaults` key `railwayToken`). With no saved sign-in, it removes `workspaceId`, so an upgraded user sees the start screen. For this reason, the welcome window never makes an `AppState`.

## A rejected token must never trap the user

[ARCHITECTURE.md](ARCHITECTURE.md#failed-loads-and-a-rejected-token) tells how Topway finds a rejected token.

- A rejected token offers **Sign in again** and **Try with sample data**, and no retry. **Refresh** in the projects header is hidden, and **Refresh Projects** (Command-R) is not available.
- A failed **Sign in again** shows its message on the open screen, because the start screen does not show while the earlier sign-in stays. The message goes in `signInAgainError`, so the rejected state stays. A new `errorMessage` removes it.
- A "Not Authorized" answer to the spend request means no billing access, which Railway gives only to workspace admins. `AppState.fetchSpend` shows `Spend.failureMessage`, does not set `isTokenRejected` and does not refresh the token (`withAccessToken(retryingRejected: false)`).

## Railway API

- **User input always goes in GraphQL `variables`, never in the query text.** This prevents injection and escaping errors. `execute(query:variables:)` takes text values, and `execute(query:json:)` takes an input object or a `null`.
- `AppState` turns each thrown `RailwayError` into `errorMessage` and never throws to a view. A cancelled request is `RailwayError.cancelled` and shows no message.
- A new `AppState` action goes in an extension file, such as `AppState+DeploymentActions.swift`, and calls `run` or `runAction`, which report each failure in the same way. A new operation of `RailwayClient` or `SampleDataSource` also goes in an extension file.
- Use `environments.serviceInstances.latestDeployment`. Railway marks `Service.serviceInstances` as deprecated.
- Railway keeps sending soft-deleted projects with `deletedAt` set. `Workspace.projectList` and `Project.environmentList` filter them out.
- The public API cannot create a project, so **New project** opens the Railway dashboard.
- For a new subscription, use the WebSocket first. Check the document on the public endpoint with no token: a valid document answers "Not Authorized", "not found" or "Problem processing request", and a wrong one answers "Cannot query field".
- `RailwayDataSource.logs` asks its token provider at each connect and each poll, because a stream can run longer than one access token (`LogTokenTests`).
- `fetchVariables` sends `unrendered: true`, as the Railway CLI does. A reference then keeps its template, and a save does not replace it with the rendered value. Do not use `Variable.references`: it has no documented format.
- Never show or copy the value of a sealed variable. The editor cannot save an empty value over it (`EnvironmentVariable.permitsSave(of:as:sealedNames:)`). A reference link has names only: never add a value to its label.
- **Topway has no price table and calculates no cost.** Show only a cost that Railway gives.
- The incident request (`platformStatus`) and the database template request (`template(code:)`) send no token. Never add the token or a variable to the incident request: [PRIVACY.md](PRIVACY.md) says that it has none.
- **After Railway accepts a database deploy, never report the add as failed because a status request failed.** A network error, a GraphQL error or the end of the wait gives `DatabaseDeployResult.pending`, and the message tells the user not to add the database again.
- Railway has no branch in `ServiceInstanceUpdateInput`, so Topway does not change the source or the branch of a service.

[ARCHITECTURE.md](ARCHITECTURE.md#feature-notes) has the notes for each feature.

## Screens

Read [DESIGN.md](DESIGN.md) before you change a screen. The rules that matter most:

- Each action has a text label, and no action shows only on hover. The only icon-only buttons are back and close, with an accessibility label and `.help`.
- Each screen uses `ScreenLayout`, with `ScreenHeader` at the top and `ActionBar` at the bottom. Lists use `LazyVStack`, and sizes come from `Layout`.
- Liquid Glass is only in the bars (`.glass`, `.glassProminent`), in one `GlassEffectContainer` for each bar. Never on a list row.
- UI text is ASD-STE100 Simplified Technical English.

### Confirmations

Use `GlassConfirmationDialog` through `destructiveConfirmation(...)`. **Never use `alert` or `confirmationDialog`**: they show in a separate window, take the key focus, and close the `MenuBarExtra(.window)` popover. Call `appState.confirm` with a `ConfirmationRequest` and its `HarmLevel`:

| Level | Result | Actions |
|---|---|---|
| Low | No dialog. | Create a variable with a new name. Create an empty environment. |
| Medium | A dialog names the service and the environment. | Restart, redeploy, edit, overwrite or delete a variable. Copy an environment (its services deploy). Save service settings. Add or delete a domain. Add a database (Railway bills its usage). Cancel, roll back or remove a deployment. |
| High | The user types the exact name. | Delete a service, a project or an environment. |

### Accessibility

[docs/accessibility.md](docs/accessibility.md) has the App Store evaluation and the manual checks. Keep these rules:

- A button that shows in each row names its item in the accessibility label, and `accessibilityInputLabels` gives Voice Control the visible text.
- A status is never color only. Each custom animation and transition reads `accessibilityReduceMotion`.
- An error that shows away from the control posts an `AccessibilityNotification.Announcement`, but only while its window appears active. `appearsActive` is in the ID of the `.task` that posts, so a closed menu bar window says nothing, and the error is said when the window opens.
- Pure wording for a label, such as `HealthSummary.statusDescription`, goes in `TopwayCore` with tests.

## Refresh and alerts

- Auto-refresh is one cancellable `Task` loop in `AppState`. A change of the setting or the interval restarts it.
- `initializeAutoRefresh()` runs from the `.task` of `MenuBarLabel`, so the refresh starts at launch, not when the popover opens. It also loads the projects one time.
- Set `alertSnapshot = nil` when the data source or the workspace changes. A `nil` snapshot gives no alerts.
- The notification center keeps a weak reference to `NotificationPresenter`, so `TopwayApp` keeps it.
- Settings asks for notification permission only when the user turns alerts on. `LaunchAtLoginToggle` reads the system state of `SMAppService.mainApp` and keeps no copy.

## Welcome window

[DESIGN.md](DESIGN.md#welcome-window) has the pages, the keys, the colors and the contrast numbers.

- **Never make an `AppState` in the welcome window**, because `AppState.init` changes the Keychain and `UserDefaults`.
- The copies of the app are app views with the data of a new `SampleDataSource` (`WelcomeSample`). **Never bundle screenshots or real account data.**
- `WelcomeFragment` keeps each copy inert. Keep all three: `allowsHitTesting(false)` (no clicks), `focusable(false)` (Tab does not stop on its buttons), and one accessibility element with `children: .ignore` and `WelcomePage.pictureDescription`.
- `FragmentProjectsHeader` and `StartFragment` copy parts of `ProjectsHeader` and `StartView`, which read `AppState`. When you change the view, change the copy.
- To see the window again in development, delete the `UserDefaults` key `welcomeWindowShown` and launch. Give `defaults delete` the full path, because `defaults delete com.pulgueta.topway` changes the container file when it exists:
  - A signed build (sandboxed): `~/Library/Containers/com.pulgueta.topway/Data/Library/Preferences/com.pulgueta.topway.plist`
  - A build with `CODE_SIGNING_ALLOWED=NO` (not sandboxed): `~/Library/Preferences/com.pulgueta.topway.plist`

## Problem reports

Topway collects no data and has no crash SDK. Problem reports go only through GitHub Issues.

- **Settings > Help** opens the link from `IssueReportLink` (`TopwayCore/Reports`, tested). It fills the device fields of a form in `.github/ISSUE_TEMPLATE` from `DeviceDetails`.
- The query item names are the field IDs of the forms, so change them together. GitHub fills only text fields from a link, so the device fields are `input` fields, not dropdowns.
- The `architecture` field reads the hardware (`hw.optional.arm64` and `sysctl.proc_translated`), not `#if arch`, so an Intel build with Rosetta gives "Apple silicon (arm64) with Rosetta".
- **Never add a token, a Workspace ID or project data to the link.**
