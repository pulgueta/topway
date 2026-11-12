# Architecture

Topway is a macOS menu bar app for Railway. The code has two parts: a core package and an app target.

## Layers

| Part | Location | Function |
|---|---|---|
| Core | `Packages/TopwayCore` | Sends requests to Railway. Keeps models and rules. Does not use SwiftUI. |
| App | `topway` | Shows the screens. Keeps the app state in `AppState`. |

The app imports the core. The core does not import the app.

### Core folders

| Folder | Contents |
|---|---|
| `API` | `RailwayDataSource`, `RailwayClient`, `RailwayError`, the GraphQL types and the WebSocket client (`GraphQLWebSocket`, `GraphQLSubscription`). |
| `API/Responses` | Types that decode Railway responses. These types are internal. |
| `Models` | `Project`, `Service`, `Deployment` and other types that the app uses. |
| `Sample` | `SampleDataSource` and its start data. |
| `Health` | `HealthSummary`, `Health`, `AlertSnapshot`, `HealthAlert` and `AlertKind`. |
| `Logs` | `LogLine`, `LogKind`, `LogEvent`, `LogConnection`, `LogBuffer` and the fallback rules. |
| `Confirmation` | `HarmLevel` and `ConfirmationRules`. |
| `Recovery` | `RecoveryAction` and `RecoveryRules`, which give the actions after a failed load. |
| `Reports` | `IssueReportLink`, which makes the link to a GitHub issue form with the `DeviceDetails` filled in. It sends no token and no project data. |
| `Storage` | `KeychainStore`, which keeps the API token in the Keychain. |

### App folders

Each folder has the name of a feature.

| Folder | Contents |
|---|---|
| `App` | App entry point, `AppState`, `MainView`, navigation, `StartView` and `SampleDataBanner`. |
| `Health` | `MenuBarLabel`, `AlertNotifier` and `NotificationPresenter`. |
| `Projects` | The projects screen, its top bar, the project rows and the project **Manage** menu. |
| `Services` | The service screen with its tabs, the service **Manage** menu, service rows and add service. |
| `Deployments` | The Deployments tab and its rows, with restart and redeploy. |
| `Logs` | The logs screen, the log line row and the connection label. |
| `Variables` | The Variables tab, its rows and the variable editor. |
| `Settings` | The native Settings window, the Alerts section and the launch at login toggle. |
| `Shared` | The screen layout, the bars, button styles, state views, the confirmation dialog and `openAppSettings`. |

## Screens

[DESIGN.md](DESIGN.md) gives the design rules. Follow it when you add or change a screen.

- The menu bar window has a fixed size of 360 × 480 points (`Layout`).
- There is no `NavigationStack`. `MainView` shows one `NavigationDestination`: the projects, add service, or one service.
- `ServiceView` shows one `ServiceDestination`: the overview, the variable editor, or the logs. The overview has the tabs **Variables** and **Deployments** (`ServiceTab`).
- `ScreenLayout` gives each screen a top bar, content and a bottom bar. `ScreenHeader` is the top bar and `ActionBar` is the bottom bar.
- Escape goes back one step. `ServiceView` handles its own steps, then `MainView` handles the others.
- Each action has a text label. No action shows only on hover.

## Data flow

1. The user does an action in a view.
2. The view calls a method on `AppState`.
3. `AppState` calls its data source. The data source is `RailwayClient`, or `SampleDataSource` in sample mode.
4. `RailwayClient` sends a GraphQL request. All user input goes in `variables`. Never put user input in the query text.
5. The data source returns a value or throws a `RailwayError`.
6. `AppState` updates its properties. If the action fails, `AppState` sets `errorMessage`.
7. The view updates. `ErrorBanner` or `ErrorStateView` shows `errorMessage`.

## Failed loads and the token

`ErrorStateView` shows a failed load. Its buttons come from `RecoveryRules.actions(isTokenRejected:isSampleMode:)`, through `AppState.recoveryActions`:

| State | Buttons |
|---|---|
| Railway did not accept the token | **Open Settings**, **Try with sample data**. No retry, because the same token fails again. |
| Other failures | **Try again**, **Open Settings**. |
| Sample mode | **Try again**. |

- `RailwayError.isTokenRejected` is `true` only for `RailwayError.unauthorized`.
- Railway answers a request that has a bad token with status 200 and the GraphQL error "Not Authorized". `RailwayError.init(graphQLErrors:)` makes `unauthorized` from that message, for HTTP requests and for the socket. An HTTP 401 also gives `unauthorized`.
- `AppState.isTokenRejected` is `true` while `errorMessage` comes from that error. Each new `errorMessage` sets it to `false`, and then `show(_:)` sets it for the new error.
- **Settings > Credentials > Remove token…** calls `AppState.removeToken()`. It deletes the token from the Keychain, removes the projects and stops the refresh. `isConfigured` is then `false`, so `MainView` shows the start screen. Sample mode stays on.

## Data sources and sample mode

`AppState` uses the `RailwayDataSource` protocol for all Railway reads and actions. Two types conform:

| Type | Function |
|---|---|
| `RailwayClient` | Sends GraphQL requests to Railway. |
| `SampleDataSource` | An actor that keeps sample data in memory. It sends no network requests. |

Sample mode lets the app run with no token, for example for App Review.

- The start screen has the **Try with sample data** button. It calls `appState.enterSampleMode()`. `ErrorStateView` has the same button when Railway does not accept the token.
- In sample mode, `MainView` shows `SampleDataBanner`. Its **Exit sample data** button calls `appState.exitSampleMode()`.
- Sample mode does not read or write the Keychain token. It is not saved, so it ends when the app quits.
- Actions change the sample data, and a later read shows the change. Redeploy adds a deployment with the current date.
- `SampleDataSource` gets the date from its `now` parameter, so tests can set a fixed date.

## Health and alerts

The projects query gets the latest deployment of each service in each environment (`environments.serviceInstances.latestDeployment`). Do not use `Service.serviceInstances`: Railway marks it as deprecated. `Project.serviceStatuses` gives one `ServiceStatus` for each service and environment that has a deployment. It leaves out environments and service instances that have `deletedAt` set.

`HealthSummary` gives one health for all projects:

| Health | Latest statuses |
|---|---|
| Failing | One or more `FAILED` or `CRASHED`. |
| In progress | No failing status, and one or more `BUILDING`, `DEPLOYING`, `INITIALIZING`, `NEEDS_APPROVAL`, `QUEUED`, `REMOVING` or `WAITING`. |
| Healthy | All other statuses, for example `SUCCESS`, `REMOVED`, `SKIPPED`, `SLEEPING` or an unknown status. No services also gives healthy. |

`MenuBarLabel` shows the health in the menu bar, with an accessibility label such as "Topway, 2 services failing".

`AlertSnapshot` keeps the last settled state (deployment ID and status) of each service in each environment. A status is settled when it is not in progress. An in-progress status does not replace the settled state, so a fix that builds first still gives a recovery alert. After each project load, `AppState` updates the snapshot:

| Change in the settled state | Alert |
|---|---|
| To `FAILED`, or a new `FAILED` deployment | Deployment failed |
| To `CRASHED`, or a new `CRASHED` deployment | Service crashed |
| From `FAILED` or `CRASHED` to `SUCCESS` | Service recovered |

There is no alert for the first load, for the same deployment with the same status, for a new or a removed service, or for a muted project. `AppState` clears the snapshot when the data source or the workspace changes, so the first load after a change gives no alerts.

`AlertNotifier` shows a local notification for each alert, only when **Send alerts** is on and the user gave permission. The notification names the service, the environment and the project. In sample mode, it shows "Sample data". `NotificationPresenter` is the notification center delegate. `TopwayApp` sets it at launch, so alerts show as banners also while the popover is open.

`UserDefaults` keeps `alertsEnabled` (off by default) and `mutedProjectIds`. Launch at login uses `SMAppService.mainApp`. The system keeps that state, so Settings reads it each time.

## Logs

### WebSocket client

`GraphQLWebSocket` sends one subscription with the `graphql-transport-ws` protocol. The URL is `wss://backboard.railway.com/graphql/v2`. It moves text frames through `MessageTransport`. `URLSessionMessageTransport` (a `URLSessionWebSocketTask`) is the live type. Tests use scripted frames and an injected sleep, with no network.

- Railway reads the token from the `Authorization: Bearer` header of the upgrade request, as the Railway CLI does. `connection_init` has no payload.
- `GraphQLSubscription` keeps the protocol rules. It has no network code, so tests can use it directly. After `connection_ack`, it sends `subscribe`. It answers `ping` with `pong`. `next` gives the data, `error` and `next` with GraphQL errors give `RailwayError.graphQLError`, and `complete` ends the stream.
- A refused upgrade with status 401, the close codes 4401 and 4403, and the message "Not Authorized" give `RailwayError.unauthorized`, the same error as an HTTP 401. HTTP requests use the same rule for the message.
- When the consumer task is cancelled, the client sends `complete` and closes the socket.
- The live socket accepts messages up to 16 MiB (`maximumMessageSize`), because one message can hold many log lines.
- `SocketKeepalive` finds a half-open socket. Every 20 seconds, it checks for a message from the server since the last check. If there is one, it sends a protocol `ping`, and Railway answers with `pong`. If there is none, the socket is dropped and the stream uses the reconnect rule. So a socket with no message for 20 seconds after a ping is dropped, at most 40 seconds after the last message. The protocol `ping` is used, not `URLSessionWebSocketTask.sendPing`, because its `pong` comes from the GraphQL server, and a proxy can answer a WebSocket ping frame.

### Log streams

`RailwayDataSource.logs(_:deploymentId:token:)` gives an `AsyncThrowingStream` of `LogEvent`: new lines, or a change of the connection (`live`, `reconnecting`, `polling`). The subscription and the query are `deploymentLogs` and `buildLogs`, with `limit: 500` and the alias `lines`.

| Socket result | Next step |
|---|---|
| A live socket drops, or a reconnect fails | Connect again with a backoff: 2, 4, 8, 16, then 30 seconds. A payload resets the backoff. The state is `reconnecting`. After 5 reconnects in a row that do not connect, poll. |
| A live socket fails 3 times in a row before it gives a payload | A network error: poll. Bad data (`decodingError`, `unknown`): stop the stream with the error. |
| The socket never connected in this stream | Poll the matching query every 5 seconds. The state is `polling`. |
| Railway sends an error, or does not accept the token | Stop the stream with the error. Polling gets the same answer. |

`LogRecovery` keeps these rules. It has no network code. While the stream polls:

- It sends one request each 5 seconds.
- A network error does not stop the stream. The next poll tries again.
- Every 60 seconds (12 polls), it tries the socket again. If the socket connects, the state is `live` again.
- The build log query also reads the deployment status. When the build is finished (the status is not `BUILDING`, `QUEUED`, `WAITING`, `INITIALIZING` or `NEEDS_APPROVAL`), polling stops and the log ends.

A server `complete` ends the stream, with no polling. The most requests in one hour: 720 polls and 60 socket tries while the stream polls. When the socket connects, gives a line and drops each time, the backoff resets, so the stream can connect up to 1,800 times in one hour.

`LogDeduplicator` removes lines that a reconnect or a poll gives again. A line is a duplicate when its timestamp, message and severity are equal to one of the last 1,000 lines. It does not compare times, because Railway can add a line with an earlier timestamp.

`SampleDataSource` gives the same sample lines for each deployment. Build logs give the build steps and end. Deploy logs give info, warning and error lines, then one line every 2 seconds. Its `sleep` parameter lets tests run with no wait.

### Logs screen

`DeploymentRow` has a **View logs** button. `ServiceView` then shows `LogsView`. The back button and Escape go to the Deployments tab.

- The screen opens on **Build** when the deployment status is `BUILDING`, `QUEUED`, `WAITING`, `INITIALIZING`, `NEEDS_APPROVAL` or `FAILED` (`Deployment.defaultLogKind`). It opens on **Deploy** for all other statuses.
- The **Build** and **Deploy** tabs each start a new stream. The stream stops when the screen closes or the tab changes.
- The footer shows the connection state. A stream that finishes with no error shows **End of log**. A stream that an error stops shows **Stopped**.
- `LogBuffer` keeps the newest 1,000 lines in memory.
- Warnings and errors have a symbol and a color, so the level does not show by color only.
- The screen follows new lines at the bottom. When the user scrolls up, it stops. **Follow new lines** starts it again. `LogScrollMetrics` keeps the rule: it checks the bottom first, so a bounce at the bottom keeps follow on.
- Errors show in `ErrorBanner`, or in `ErrorStateView` with **Try again** when there are no lines.

## Confirmation levels

Each action that changes data has a `HarmLevel`.

| Level | Result | Actions |
|---|---|---|
| Low | No dialog. | Create a variable with a new name. |
| Medium | A dialog names the service and the environment. | Restart, redeploy, edit a variable, save a variable with a name that exists, delete a variable. |
| High | The user must type the exact name. | Delete a service, delete a project. |

A production environment shows a red label in the dialog.

To ask for a confirmation, make a `ConfirmationRequest` and call `appState.confirm`. `MainView` shows `GlassConfirmationDialog` above all screens with `destructiveConfirmation(...)`. Do not use `alert` or `confirmationDialog`, because they close the menu bar window. Return confirms only an action that is not destructive.

The Settings window is a separate window, so **Remove token…** asks for its confirmation in the Settings form.

## Add a feature

1. Add the request to `RailwayDataSource` and `RailwayClient`. Add tests with `StubServer` first.
2. Add the same action to `SampleDataSource`, so it changes the sample data. Add tests first.
3. Add new response types to `API/Responses`. Add new public models to `Models`.
4. Add a method on `AppState`. Set `errorMessage` when the action fails.
5. Add the views to a feature folder. Make a new folder if no folder is correct. Follow [DESIGN.md](DESIGN.md): use `ScreenLayout`, give each action a text label, and keep glass on the bars.
6. If the action changes data, select a `HarmLevel` and use `appState.confirm`.
