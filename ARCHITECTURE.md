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
| `API` | `RailwayDataSource`, `RailwayClient`, `RailwayError` and the GraphQL types. |
| `API/Responses` | Types that decode Railway responses. These types are internal. |
| `Models` | `Project`, `Service`, `Deployment` and other types that the app uses. |
| `Sample` | `SampleDataSource` and its start data. |
| `Confirmation` | `HarmLevel` and `ConfirmationRules`. |
| `Storage` | `KeychainStore`, which keeps the API token in the Keychain. |

### App folders

Each folder has the name of a feature.

| Folder | Contents |
|---|---|
| `App` | App entry point, `AppState`, `MainView`, navigation and `SampleDataBanner`. |
| `Projects` | Project list rows. |
| `Services` | Service rows and add service. |
| `Deployments` | Deployment list, restart and redeploy. |
| `Variables` | Variable list, variable editor and the service actions menu. |
| `Settings` | The native Settings window. |
| `Shared` | Buttons, error views, the confirmation dialog and `openAppSettings`. |

## Data flow

1. The user does an action in a view.
2. The view calls a method on `AppState`.
3. `AppState` calls its data source. The data source is `RailwayClient`, or `SampleDataSource` in sample mode.
4. `RailwayClient` sends a GraphQL request. All user input goes in `variables`. Never put user input in the query text.
5. The data source returns a value or throws a `RailwayError`.
6. `AppState` updates its properties. If the action fails, `AppState` sets `errorMessage`.
7. The view updates. `ErrorBanner` or `ErrorStateView` shows `errorMessage`.

## Data sources and sample mode

`AppState` uses the `RailwayDataSource` protocol for all Railway reads and actions. Two types conform:

| Type | Function |
|---|---|
| `RailwayClient` | Sends GraphQL requests to Railway. |
| `SampleDataSource` | An actor that keeps sample data in memory. It sends no network requests. |

Sample mode lets the app run with no token, for example for App Review.

- The start screen has the **Try with sample data** button. It calls `appState.enterSampleMode()`.
- In sample mode, `MainView` shows `SampleDataBanner`. Its **Exit sample data** button calls `appState.exitSampleMode()`.
- Sample mode does not read or write the Keychain token. It is not saved, so it ends when the app quits.
- Actions change the sample data, and a later read shows the change. Redeploy adds a deployment with the current date.
- `SampleDataSource` gets the date from its `now` parameter, so tests can set a fixed date.

## Confirmation levels

Each action that changes data has a `HarmLevel`.

| Level | Result | Actions |
|---|---|---|
| Low | No dialog. | Create a variable with a new name. |
| Medium | A dialog names the service and the environment. | Restart, redeploy, edit a variable, save a variable with a name that exists, delete a variable. |
| High | The user must type the exact name. | Delete a service, delete a project. |

A production environment shows a red label in the dialog.

To ask for a confirmation, make a `ConfirmationRequest` and call `appState.confirm`. `MainView` shows `GlassConfirmationDialog` above all screens with `destructiveConfirmation(...)`. Do not use `alert` or `confirmationDialog`, because they close the menu bar window.

## Add a feature

1. Add the request to `RailwayDataSource` and `RailwayClient`. Add tests with `StubServer` first.
2. Add the same action to `SampleDataSource`, so it changes the sample data. Add tests first.
3. Add new response types to `API/Responses`. Add new public models to `Models`.
4. Add a method on `AppState`. Set `errorMessage` when the action fails.
5. Add the views to a feature folder. Make a new folder if no folder is correct.
6. If the action changes data, select a `HarmLevel` and use `appState.confirm`.
