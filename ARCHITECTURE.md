# Architecture

This page tells you where the Topway code goes and how data moves through the app.

## Layers

| Part | Location | What it does |
|---|---|---|
| Core | `Packages/TopwayCore` | Sends requests to Railway, and keeps the models and the rules. It does not use SwiftUI. |
| App | `topway` | Shows the screens, and keeps the app state in `AppState`. |

The app imports the core. The core never imports the app.

### Core folders

| Folder | Contents |
|---|---|
| `API` | `RailwayDataSource`, `RailwayClient`, `RailwayError`, the GraphQL types and the WebSocket client (`GraphQLWebSocket`, `GraphQLSubscription`). |
| `API/Responses` | Internal types that decode Railway responses. |
| `Models` | `Project`, `Service`, `Deployment` and the other types that the app uses. |
| `Sample` | `SampleDataSource` and its start data. |
| `OAuth` | Sign in with Railway: `PKCE`, `AuthorizationRequest`, `AuthorizationCallback`, `RailwayOAuthClient`, `OAuthTokens`, `WorkspaceChoice` and `SessionGeneration`. |
| `Storage` | `KeychainStore`, which keeps the tokens in the Keychain. |
| `Health` | `HealthSummary`, `Health`, `AlertSnapshot`, `HealthAlert` and `AlertKind`. |
| `Logs` | `LogLine`, `LogKind`, `LogEvent`, `LogConnection`, `LogBuffer` and the reconnect and polling rules. |
| `Confirmation` | `HarmLevel` and `ConfirmationRules`. |
| `Recovery` | `RecoveryAction` and `RecoveryRules`: the actions after a failed load. |
| `Reports` | `IssueReportLink`: the link to a GitHub issue form, with the `DeviceDetails` filled in. It has no token and no project data. |
| `References` | Variable references, reference completion and the service graph. |
| `Environments`, `Settings`, `Domains`, `Databases`, `Metrics`, `Spend`, `Status` | The rules of the feature with the same name. `Settings` is for service settings, and `Status` is for the Railway incident banner. See [Feature notes](#feature-notes). |

### App folders

Each folder has the name of a feature.

| Folder | Contents |
|---|---|
| `App` | The entry point, `AppState` and its extensions, `MainView`, navigation, `StartView`, `SampleDataBanner` and `IncidentBanner`. |
| `App/Welcome` | The welcome window. See [Welcome window](#welcome-window). |
| `Health` | `MenuBarLabel`, `AlertNotifier` and `NotificationPresenter`. |
| `Projects` | The projects screen, its top bar, the project rows and the project **Manage** menu. |
| `Services` | The service screen and its tabs, the service **Manage** menu, the service rows, service settings and add service. |
| `Deployments`, `Logs`, `Variables`, `Metrics`, `Domains`, `Environments`, `ServiceLinks`, `Spend` | The screens and rows of each feature. |
| `SignIn` | `WebSignIn` (the `ASWebAuthenticationSession` window), `SignInButton` and the workspace list. |
| `Settings` | The Settings window: Account, Alerts, launch at login and Help. |
| `Shared` | The screen layout, the bars, button styles, state views, the confirmation dialog and `openAppSettings`. |

## Scenes

`TopwayApp` has three scenes.

| Scene | What it shows |
|---|---|
| `MenuBarExtra` (style `.window`) | The menu bar icon (`MenuBarLabel`) and the menu bar window (`MainView`). |
| `Window` (`id: "welcome"`) | The welcome window (`WelcomeView`), only at the first launch. |
| `Settings` | The native Settings window. |

### Welcome window

Topway has no Dock icon (`LSUIElement`), so the welcome window shows a new user where the menu bar icon is.

- `defaultLaunchBehavior` is `.presented` until the `UserDefaults` key `welcomeWindowShown` is set, and `.suppressed` after. `WelcomeView` sets the key when it appears, and activates the app so the window comes to the front. No setting shows the window again.
- `restorationBehavior(.disabled)` keeps the window closed at the next launch. `windowResizability(.contentSize)` gives it a fixed size.
- `WelcomeView` loads the sample data for the copies of the app in a `.task` with `WelcomeSample.load()`, from a new `SampleDataSource` that sends no request. It never makes an `AppState`, because `AppState.init` changes the Keychain and `UserDefaults`.
- Previews set the data before they render (`WelcomeSamplePreview`, through the `welcomeSample` environment value), because a static preview does not wait for the task.

[DESIGN.md](DESIGN.md#welcome-window) has the pages, the sizes, the colors and the accessibility rules.

## Screens and navigation

- There is no `NavigationStack`. `MainView` shows one `NavigationDestination`: the projects, usage, add service, environments, service links or one service.
- `ServiceView` shows one `ServiceDestination`: the overview, the variable editor, the logs, the settings or the domains. The overview has the tabs **Variables**, **Deployments** and **Metrics** (`ServiceTab`).
- Escape goes back one step. `ServiceView` handles its own steps first, then `MainView` handles the others.

Follow [DESIGN.md](DESIGN.md) when you add or change a screen.

## Data flow

1. A view calls a method on `AppState`, which calls its data source: `RailwayClient`, or `SampleDataSource` in sample mode.
2. `RailwayClient` sends a GraphQL request. All user input goes in `variables`. Never put user input in the query text.
3. The data source returns a value or throws a `RailwayError`.
4. `AppState` updates its properties. Most write methods then call `loadProjects()`. When an action fails, `AppState` sets `errorMessage`, and `ErrorBanner` or `ErrorStateView` shows it.

## Sign in with Railway

Sign in with Railway is the only way to connect. Topway is a Railway OAuth app of the type Native (Public), with PKCE S256 and no client secret.

1. **Sign in with Railway** calls `AppState.signIn()`. `WebSignIn` opens the Railway page in an `ASWebAuthenticationSession` window, with the HTTPS callback `https://topway.pulgueta.com/oauth/callback` (Associated Domains `webcredentials`).
2. `AuthorizationCallback.code(in:state:)` checks the callback. `RailwayOAuthClient.exchange` sends the code, the client ID and the PKCE verifier. Topway saves `OAuthTokens` in the Keychain as one item.
3. `AppState.loadAccount()` reads the name, the email and the shared workspaces. `WorkspaceChoice` selects the saved workspace or the only one. With several, the projects screen shows the workspace list.
4. `AppState.withAccessToken` gives each request a token. It refreshes the token 5 minutes before it expires, and one time after a "Not Authorized" answer. Only one refresh runs at a time.
5. `SessionGeneration` changes on a new sign-in, a sign-out and sample mode, but not on a refresh. A late answer from an earlier generation changes nothing, and a sign-out or sample data closes the sign-in window.

The client ID comes from the build (see [AGENTS.md](AGENTS.md#oauth-client-id)). With no value, the start screen offers only sample data. At launch, `AppState` removes the API token of earlier builds and does not use it.

## Failed loads and a rejected token

`ErrorStateView` shows a failed load. Its buttons come from `RecoveryRules.actions(isTokenRejected:isSampleMode:)`, through `AppState.recoveryActions`:

| State | Buttons |
|---|---|
| Railway did not accept the token | **Sign in again** and **Try with sample data**. No retry, because the same token fails again. |
| Other failures | **Try again** and **Open Settings**. |
| Sample mode | **Try again**. |

- Railway answers a request with a bad token with status 200 and the GraphQL error "Not Authorized". `RailwayError.init(graphQLErrors:)` makes `unauthorized` from that message, for HTTP requests and for the socket. An HTTP 401 also gives `unauthorized`, and `RailwayError.isTokenRejected` is `true` only for it.
- `AppState.isTokenRejected` is `true` while `errorMessage` comes from that error, after one refresh did not help.
- When Railway does not accept the refresh token, the sign-in ends, and the start screen shows why.
- **Settings > Account > Sign out…** calls `AppState.signOut()`. It deletes the tokens from the Keychain, removes the workspace choice and the projects, and stops the refresh. `isConfigured` is then `false`, so `MainView` shows the start screen. Sample mode stays on.

## Sample mode

`AppState` uses the `RailwayDataSource` protocol for all Railway reads and actions. In sample mode, the data source is `SampleDataSource`: an actor that keeps sample data in memory and sends no request. Sample mode lets the app run with no Railway account, for example for App Review.

- **Try with sample data** calls `appState.enterSampleMode()`. It is on the start screen, and in `ErrorStateView` when Railway does not accept the token.
- `MainView` shows `SampleDataBanner`. Its **Exit sample data** button calls `appState.exitSampleMode()`.
- Sample mode does not read or write the tokens. It is not saved, so it ends when the app quits.
- Actions change the sample data, and a later read shows the change. Redeploy adds a deployment with the current date.
- `SampleDataSource` takes `now` and `sleep` parameters, so tests can set a fixed date and run with no wait.

## Health and alerts

The projects query gets the latest deployment of each service in each environment (`environments.serviceInstances.latestDeployment`). Do not use `Service.serviceInstances`: Railway marks it as deprecated. `Project.serviceStatuses` gives one `ServiceStatus` for each service and environment that has a deployment. It leaves out environments and service instances that have `deletedAt` set.

`HealthSummary` gives one health for all projects:

| Health | Latest statuses |
|---|---|
| Failing | One or more `FAILED` or `CRASHED`. |
| In progress | No failing status, and one or more `BUILDING`, `DEPLOYING`, `INITIALIZING`, `NEEDS_APPROVAL`, `QUEUED`, `REMOVING` or `WAITING`. |
| Healthy | All other statuses, for example `SUCCESS`, `REMOVED`, `SKIPPED`, `SLEEPING` or an unknown status. No services also gives healthy. |

`MenuBarLabel` shows the health in the menu bar, with an accessibility label such as "Topway, 2 services failing" (`HealthSummary.statusDescription`).

`AlertSnapshot` keeps the last settled state (deployment ID and status) of each service in each environment. A status is settled when it is not in progress. An in-progress status does not replace the settled state, so a fix that builds first still gives a recovery alert. After each project load, `AppState` updates the snapshot:

| Change in the settled state | Alert |
|---|---|
| To `FAILED`, or a new `FAILED` deployment | Deployment failed |
| To `CRASHED`, or a new `CRASHED` deployment | Service crashed |
| From `FAILED` or `CRASHED` to `SUCCESS` | Service recovered |

There is no alert for the first load, for the same deployment with the same status, for a new or a removed service, or for a muted project. `AppState` clears the snapshot when the data source or the workspace changes, so the first load after a change gives no alerts.

- `AlertNotifier` shows a local notification for each alert, only when **Send alerts** is on and the user gave permission. The notification names the service, the environment and the project. In sample mode, it shows "Sample data".
- `NotificationPresenter` is the notification center delegate. `TopwayApp` sets it at launch, so alerts show as banners also while the menu bar window is open.
- `UserDefaults` keeps `alertsEnabled` (off by default) and `mutedProjectIds`.
- Launch at login uses `SMAppService.mainApp`. The system keeps that state, so Settings reads it each time.

## Logs

### WebSocket client

`GraphQLWebSocket` sends one subscription with the `graphql-transport-ws` protocol to `wss://backboard.railway.com/graphql/v2`. It moves text frames through `MessageTransport`, so tests use scripted frames (`ScriptedTransport`, `ScriptedConnector`) and an injected sleep, with no network.

- Railway reads the token from the `Authorization: Bearer` header of the upgrade request, as the Railway CLI does. `connection_init` has no payload.
- `GraphQLSubscription` keeps the protocol rules and has no network code, so tests use it directly. A GraphQL error in `error` or `next` gives `RailwayError.graphQLError`.
- A refused upgrade with status 401, the close codes 4401 and 4403, and the message "Not Authorized" give `RailwayError.unauthorized`, the same error as an HTTP 401.
- The socket accepts messages up to 16 MiB (`maximumMessageSize`), because one message can hold many log lines.
- `SocketKeepalive` finds a half-open socket. Every 20 seconds, it checks for a message from the server since the last check. If there is one, it sends a protocol `ping`. If there is none, it drops the socket, and the stream connects again. So a dead socket drops at most 40 seconds after its last message.
- The keepalive uses the protocol `ping`, not `URLSessionWebSocketTask.sendPing`. The GraphQL server sends the protocol `pong`, but a proxy can answer a WebSocket ping frame.

### Log streams

`RailwayDataSource.logs(_:deploymentId:token:)` gives an `AsyncThrowingStream` of `LogEvent`: new lines, or a change of the connection (`live`, `reconnecting`, `polling`). The subscription and the query are `deploymentLogs` and `buildLogs`, with `limit: 500` and the alias `lines`.

| Socket result | Next step |
|---|---|
| A live socket drops, or a reconnect fails | Connect again with a backoff: 2, 4, 8, 16, then 30 seconds. A payload resets the backoff. The state is `reconnecting`. After 5 reconnects in a row that do not connect, poll. |
| A live socket fails 3 times in a row before it gives a payload | A network error: poll. Bad data (`decodingError`, `unknown`): stop the stream with the error. |
| The socket never connected in this stream | Poll the matching query every 5 seconds. The state is `polling`. |
| Railway sends an error, or does not accept the token | Stop the stream with the error. Polling gets the same answer. |

`LogRecovery` keeps these rules and has no network code. While the stream polls, a network error does not stop it, and every 60 seconds (12 polls) it tries the socket again. The build log query also reads the deployment status: when the build is finished (the status is not `BUILDING`, `QUEUED`, `WAITING`, `INITIALIZING` or `NEEDS_APPROVAL`), the log ends.

A server `complete` ends the stream, with no polling. In one hour, a polling stream sends at most 720 polls and 60 socket tries. A socket that connects, gives a line and drops each time resets the backoff, so a stream can connect up to 1,800 times in one hour.

`LogDeduplicator` removes lines that a reconnect or a poll gives again. A line is a duplicate when its timestamp, message and severity are equal to one of the last 1,000 lines. It does not compare times, because Railway can add a line with an earlier timestamp.

`SampleDataSource` gives sample lines. Build logs end, and deploy logs add one line every 2 seconds.

### Logs screen

- `LogsView` opens on **Build** when the deployment status is `BUILDING`, `QUEUED`, `WAITING`, `INITIALIZING`, `NEEDS_APPROVAL` or `FAILED` (`Deployment.defaultLogKind`), and on **Deploy** for all other statuses.
- The **Build** and **Deploy** tabs each start a new stream. The stream stops when the screen closes or the tab changes.
- `LogBuffer` keeps the newest 1,000 lines in memory.
- The screen follows new lines until the user scrolls up. `LogScrollMetrics` checks the bottom first, so a bounce at the bottom keeps follow on.

## Feature notes

Each feature keeps its pure rules in a `TopwayCore` folder, with tests.

### Metrics

- `fetchMetrics` reads the `metrics` query for one service in one environment. `MetricWindow` gives the start date and `sampleRateSeconds` (30, 60 or 240, as the Railway CLI does).
- `MetricsView` loads on open, on a new time range and on **Refresh**. It does not poll.

### Environments and service settings

- `environmentCreate` takes `projectId`, `name` and an optional `sourceEnvironmentId`. With a source, Railway copies its services, variables and settings.
- `ServiceSettings.changes(from:)` sends only the changed values: `serviceUpdate` for a new name (all environments), and `serviceInstanceUpdate` for the other settings (one environment). An empty field goes as `null`.
- To add a service setting, add a case to `ServiceSetting` (the raw value is the field name on Railway) and to the response type.

### Domains

- A service gets one Railway domain in an environment (`DomainRules.canAddRailwayDomain`). `CustomDomainStatus.records` gives the records of Railway, then a TXT record `railway-verify=<token>` at `verificationDnsHost` until `verified` is true, as the Railway CLI shows them.
- Topway shows a domain as text and does not open it.

### Databases

- The raw values of `DatabaseTemplate` (`postgres`, `mysql`, `redis`, `mongo`) are the template codes on Railway.
- `deployDatabase` reads the public template, gives each variable its default (`TemplateConfig.filled`), and sends `templateDeployV2`. A variable with no default that is not optional stops the deploy (`TemplateConfigProblem`), because Topway has no screen to ask for it.
- `waitForDatabase` asks `workflowStatus` each 2 seconds, at most 30 times and 60 seconds, with a 10-second limit for each request. `Complete` ends the wait, `Error` throws, and all other answers wait.

### Variables and references

- A value can hold `${{api.VAR}}` (a service), `${{shared.VAR}}` (a shared variable) and `${{VAR}}` (the same service), with spaces inside the braces. A service name follows the rule of the Railway CLI (`auto_wrap_reference`). Malformed text, such as `secret(32)`, gives no target.
- `fetchProjectVariables` reads the shared variables and the variables of each service in one request, with the aliases `s0`, `s1`…
- A sealed variable shows "Sealed" with a lock. **Copy all** gives a `#` comment line with its name only. A save replaces the value, and Railway keeps it sealed. The sample data has one: `STRIPE_SECRET_KEY` of the storefront API.

### Service links

- `ServiceGraph` makes one edge for each pair of services, with the sorted names of the variables. A reference to the same service gives no edge.
- When a reload removes the selected environment, `EnvironmentSelection.reconciled` selects the first one. `ServiceView` uses the same rule: it goes back to its overview and closes an open dialog. With no environment, it shows "No environments" and disables **Settings**, **Domains** and **Redeploy**.

### Deployments

`Deployment.availableActions` gives the **Manage** menu: cancel for a build or a deploy in progress, roll back when Railway gives `canRollback: true`, and remove for a deployment that runs, crashed or sleeps.

### Spend

`workspace.customer` gives `currentUsage` (Railway calculates it in US dollars and keeps it in a cache), `billingPeriod` and `usageLimit`. A `softLimit` of 0 is not set. Then `usage`, with `includeDeleted: true` as the Railway CLI does, gives the totals of each `UsageKind`.

### Incident banner

- An incident is open when its status is not `RESOLVED`. `PlatformIncident.link` opens only an HTTPS page on railway.com, or else `https://status.railway.com`.
- `IncidentCheck.isDue` permits one request in 5 minutes. A failed check keeps the last answer and shows no error. VoiceOver says each incident one time.
- Topway does not use the JSON of the status page, because it is about 570 KB for each request and has no schema.

## Confirmations

Each action that changes data has a `HarmLevel`. [AGENTS.md](AGENTS.md#confirmations) lists the levels and the actions. A production environment shows a red label in the dialog.

To ask for a confirmation, make a `ConfirmationRequest` and call `appState.confirm`. `MainView` shows `GlassConfirmationDialog` above all screens, with `destructiveConfirmation(...)`. Do not use `alert` or `confirmationDialog`, because they close the menu bar window. Return confirms only an action that is not destructive.

The Settings window is a separate window, so **Sign out…** asks for its confirmation in the Settings form.

## Add a feature

1. Add the request to `RailwayDataSource` and `RailwayClient`. Write tests with `StubServer` first.
2. Add the same action to `SampleDataSource`, so it changes the sample data. Write tests first.
3. Add new response types to `API/Responses`, and new public models to `Models`.
4. Add a method on `AppState`. Set `errorMessage` when the action fails.
5. Add the views to a feature folder. Make a new folder if no folder fits. Follow [DESIGN.md](DESIGN.md): use `ScreenLayout`, give each action a text label, and keep glass on the bars.
6. If the action changes data, select a `HarmLevel` and use `appState.confirm`.
