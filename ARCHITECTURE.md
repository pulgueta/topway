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
| `API` | `RailwayClient`, `RailwayError` and the GraphQL types. |
| `API/Responses` | Types that decode Railway responses. These types are internal. |
| `Models` | `Project`, `Service`, `Deployment` and other types that the app uses. |
| `Confirmation` | `HarmLevel` and `ConfirmationRules`. |

### App folders

Each folder has the name of a feature.

| Folder | Contents |
|---|---|
| `App` | App entry point, `AppState`, `MainView` and navigation. |
| `Projects` | Project list rows. |
| `Services` | Service rows, add service and delete service. |
| `Deployments` | Deployment list, restart and redeploy. |
| `Variables` | Variable list and variable editor. |
| `Settings` | Settings screen. |
| `Shared` | Buttons, error views and the confirmation dialog. |

## Data flow

1. The user does an action in a view.
2. The view calls a method on `AppState`.
3. `AppState` calls `RailwayClient`.
4. `RailwayClient` sends a GraphQL request. All user input goes in `variables`. Never put user input in the query text.
5. `RailwayClient` returns a value or throws a `RailwayError`.
6. `AppState` updates its properties. If the action fails, `AppState` sets `errorMessage`.
7. The view updates. `ErrorBanner` or `ErrorStateView` shows `errorMessage`.

## Confirmation levels

Each action that changes data has a `HarmLevel`.

| Level | Result | Actions |
|---|---|---|
| Low | No dialog. | Create a variable. |
| Medium | A dialog names the service and the environment. | Restart, redeploy, edit a variable, delete a variable. |
| High | The user must type the exact name. | Delete a service, delete a project. |

A production environment shows a red label in the dialog.

To ask for a confirmation, make a `ConfirmationRequest` and call `appState.confirm`. `MainView` shows the dialog above all screens.

## Add a feature

1. Add the request to `RailwayClient`. Add tests with `StubServer` first.
2. Add new response types to `API/Responses`. Add new public models to `Models`.
3. Add a method on `AppState`. Set `errorMessage` when the action fails.
4. Add the views to a feature folder. Make a new folder if no folder is correct.
5. If the action changes data, select a `HarmLevel` and use `appState.confirm`.
