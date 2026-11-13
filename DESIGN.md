# Design

These are the design rules of the Topway menu bar window and the welcome window. Read them before you change a screen.

## Direction

Topway uses **native SwiftUI controls with text labels**. Liquid Glass comes from the system button styles, and only on the control layer. Topway does not draw custom glass controls.

In a user test, the first design hid actions until the pointer was on a row, or put them in a menu behind an icon. Its icons had no text, and the same arrow meant Refresh, Restart and Redeploy. This direction fixes both problems, for these reasons:

- Apple says to use standard components, because they get Liquid Glass and its accessibility behavior automatically. See [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass).
- Apple says to use custom Liquid Glass effects sparingly and not in the content layer. See [Materials](https://developer.apple.com/design/human-interface-guidelines/materials). Custom glass on rows also costs more to draw in a list, and needs custom work for each accessibility setting.
- A text label says what a button does. An icon alone does not. See [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons).
- The system draws standard controls fast, and they need no hover state in each row.

## Window

- The window is a `MenuBarExtra` with the `.window` style. The Human Interface Guidelines prefer a menu for a menu bar extra, but Topway edits variables, shows live logs and asks the user to type a name, so a menu cannot hold it. See [The menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar#Menu-bar-extras) and [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra).
- The size is fixed at **360 × 480 points** (`Layout.windowWidth`, `Layout.windowHeight`). Text labels need the width, and a fixed size keeps the window stable when the content changes.
- Settings is the native `Settings` scene, in its own window.

## Layout

Each screen has the same parts, from top to bottom. `ScreenLayout` puts them together.

| Part | Contents | Component |
|---|---|---|
| Sample data banner | Shows on all screens in sample mode. | `SampleDataBanner` |
| Incident banner | Shows on all screens while Railway reports an open incident. The user can hide it. | `IncidentBanner` |
| Top bar | A back button with the name of the earlier screen, the title, and at most one control. | `ScreenHeader`, `ProjectsHeader` |
| Context | What the content belongs to: the project, the environment, the tabs. | `ServiceContextBar` |
| Content | A list, a form, or one state: loading, empty or error. | See [States](#states). |
| Error message | The error of a failed action. The content stays visible. | `ErrorBanner` |
| Bottom bar | A short status on the leading side, and the actions of the screen on the trailing side. | `ActionBar` |

The bars are the control layer. The content is the content layer.

## Navigation

There is no `NavigationStack`. `MainView` and `ServiceView` each hold an enum of screens.

```text
Projects (start screen with no sign-in; workspace list after a sign-in with several workspaces)
├── Usage
├── Add service
├── Environments
│   └── New environment
├── Service links
└── Service: tabs Variables | Deployments | Metrics
    ├── Add variable / Edit variable
    ├── Settings
    ├── Domains
    │   └── Add custom domain
    └── Logs: tabs Build | Deploy
```

- Variables, Deployments and Metrics are tabs of one service screen. A tab must not be in a menu.
- The back button shows where it goes, for example **Projects**.
- Escape goes back one step. In a dialog, Escape cancels.
- The service screen keeps the selected tab when the user comes back from the editor or the logs.

## Action rules

1. Each action has a text label. Do not show an action only on hover or only on keyboard focus.
2. Only two icon-only buttons are permitted: back and close. They must have an accessibility label and a `.help` text. At this time, only the close button of `ErrorBanner` has no text.
3. Put the actions of a screen in the bottom bar. At most one is prominent (`.glassProminent`): the action that the user does most.
4. Put the actions of a row in the row, as small bordered buttons.
5. Use a menu only for the rare actions of one item, with the text label **Manage**. The primary action is also visible outside the menu. See [Pull-down buttons](https://developer.apple.com/design/human-interface-guidelines/pull-down-buttons).
   - Project: Add service, Environments, Service links, Mute alerts and Delete project.
   - Service: Settings, Domains, Redeploy and Delete service.
   - Deployment: Roll back, Cancel deployment and Remove deployment, only the actions that the deployment permits.
6. Put a destructive action last, after a divider. Its text is red, and its label ends with "…" when a confirmation follows. A menu item gets red text from `role: .destructive`. A bordered button also needs `.foregroundStyle(.red)`, because on macOS the role alone does not change its color.
7. Each action that changes data goes through `appState.confirm`, and `GlassConfirmationDialog` shows in the window. Do not use `alert`, `confirmationDialog` or a sheet, because they close the menu bar window.
8. In a dialog, Return confirms only an action that is not destructive.
9. When the action of a dialog has the word "Cancel", change the label of the other button (`cancelTitle`), for example **Keep deployment** and **Cancel deployment**.

## Components

All shared components are in `topway/Shared`.

| Component | Use |
|---|---|
| `Layout` | Sizes and spaces. Do not write these numbers in a view. |
| `ScreenLayout` | Top bar, content and bottom bar of each screen. |
| `ScreenHeader` | Top bar of a screen below the projects list. |
| `ActionBar` | Bottom bar with a status and actions. |
| `RowButtonStyle` | A full-width row that the user selects, such as a service. |
| `CopyButton` | Copies, then shows "Copied" for 2 seconds. |
| `LoadingStateView` | The first load of a screen. |
| `ErrorStateView`, `RecoveryButton` | A failed load, with the actions of `RecoveryRules`. |
| `ErrorBanner` | A failed action. |
| `GlassConfirmationDialog` | A confirmation, through `destructiveConfirmation(...)`. |

Use these system controls directly: `Button`, `Menu`, `Picker`, `Toggle`, `TextField`, `ContentUnavailableView` for an empty state, and `Form` in Settings. A `Picker` is segmented for 2 or 3 tabs, a menu for a list of environments or time ranges, and a radio group for a short list of options in a form.

## Liquid Glass

- Glass is only on the control layer: the buttons of the top bar and the bottom bar ([`.buttonStyle(.glass)`](https://developer.apple.com/documentation/swiftui/glassbuttonstyle), `.glassProminent`), the **Follow new lines** button on the logs, the bottom bar of the welcome window, and the card of the confirmation dialog ([`glassEffect`](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))).
- Never put glass on a list row, on a form field or on a panel of content.
- Put the glass buttons of one bar in one `GlassEffectContainer`, so the system draws them in one pass. See [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer).
- Do not put glass on glass. The buttons in the dialog card use `.bordered` and `.borderedProminent`.
- With Reduce Transparency, the dialog card is opaque. The system changes the glass of its own button styles.
- The bars are above and below the content, not on it (`ScreenLayout` is a `VStack`). The content is clipped between the bars, so no row can scroll under a bar and show through its text. Do not use `safeAreaBar` or `safeAreaInset` for a bar: a scroll view then goes under the bar, and on macOS the rows show through it.
- For the rules of the effect, see [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views).

## Type, color and space

- Use the system text styles: `.headline` for a screen title, `.body` for a row title, `.callout` for context and messages, `.subheadline` for a status or a date. Use a monospaced design for variable names, variable values and log lines.
- Use `.fontWeight(.medium)` only for the main text of a row.
- Use `.title` with the semibold weight only for the one number that a screen is about, such as the cost on the usage screen.
- Use the hierarchical styles `.secondary` and `.tertiary` for less important text and icons. Do not set an opacity on text.
- Color has a meaning: orange for sample data and warnings; red for errors and destructive actions; green, yellow, red, purple and gray for the deployment status; the accent color for the prominent button.
- A color is never the only sign. A text or a symbol is always with it.
- Do not put orange text on a tint, and do not put white text on a system color. The system colors change with Increase Contrast, and such text is then hard to read. Color the symbol, or use red text with a symbol.
- Icons in rows are monochrome.
- A chart (`MetricCard`, Swift Charts) is content: no glass, no axis, and one series in the tint color. The values that matter are text next to the chart, so the chart is never the only way to read a value. The chart height is `Layout.chartHeight`.
- Use the constants of `Layout` for padding and spacing.

## Motion

- There is one animation: `Animation.screenChange` (ease in and out, 0.2 seconds). It is for a change of screen, a project that opens or closes, and the dialog.
- A screen one level down moves in from the trailing edge. With Reduce Motion, it only fades (`AnyTransition.screen(reduceMotion:)`).
- Each custom animation and transition reads `accessibilityReduceMotion`. With Reduce Motion, a project opens and closes with no animation, and the dialog only fades.
- The incident banner shows and hides with no animation.
- No animation on hover, and no animation that repeats. The only timer is the 2 seconds of `CopyButton`.

## States

| State | Content |
|---|---|
| First load | `LoadingStateView` with a text, for example "Loading projects…". |
| Reload | The list stays. The Refresh button is not available until the load ends. |
| Empty | `ContentUnavailableView` that says what is missing and which button adds it. |
| Load failed | `ErrorStateView`. The title says what did not load. The buttons come from `RecoveryRules`. |
| Action failed | `ErrorBanner` above the bottom bar. |

When Railway does not accept the token, `ErrorStateView` shows **Sign in again** and **Try with sample data**, and no retry. **Sign out…** in Settings shows the start screen again. Sample data stays until the user exits it, and then the start screen shows.

## Copy

- Write in ASD-STE100 Simplified Technical English: short sentences, active voice, one instruction in each sentence.
- A button label starts with a verb and names the object: **Add variable**, **View logs**, **Sign in with Railway**.
- Use sentence-style capitalization for buttons, titles and messages. Use title-style capitalization for the section headers in Settings.
- A message says what occurred and what the user can do.
- A `.help` text says what the control does in one sentence.

## Accessibility and keyboard

- Each control has a text label, so VoiceOver and Voice Control can use it. A row is a container with the name of its item. A button that shows in each row names its item in the accessibility label, for example "Copy value of DATABASE_URL".
- When the accessibility label has more words than the visible text, add `accessibilityInputLabels` with the visible text first, so Voice Control accepts the text that the user sees.
- Post an `AccessibilityNotification.Announcement` for a result that shows away from the control. `ErrorBanner`, `ErrorStateView` and `CopyButton` do this.
- The dialog hides the content behind it from assistive technologies, and moves the VoiceOver focus into the card.
- Symbols that only decorate are hidden from VoiceOver. A hidden value reads as "Hidden value".
- The system controls support Full Keyboard Access, Increase Contrast and Reduce Transparency.
- Escape goes back. Return adds a service from its text field. Command-Return saves a variable or the service settings. Command-R refreshes the projects.
- [docs/accessibility.md](docs/accessibility.md) has the evaluation for the App Store labels and the manual checks. Do the evaluation again when you change a screen.

## Performance

- Lists use `ScrollView` with `LazyVStack`.
- No glass effect in a row. A screen has at most 6 glass shapes.
- A row has no hover state for its actions. Only `RowButtonStyle` keeps a hover flag, in the row that the pointer is on.
- A reload keeps the list on the screen. Only the first load shows a progress indicator.
- Views read only the `AppState` properties that they show, so a change updates only those views.

These are accepted tradeoffs:

- The content does not scroll under the bars, so the window has no scroll edge effect. A row stops at the edge of a bar. With `safeAreaBar`, the rows showed through the bar text after a change of screen.
- `Deployment.formattedDate` makes date formatters on each call. The deployments list is short, so this stays.
- Rows are tall, because their actions are always visible. The window height of 480 points keeps enough rows visible.

## Screens

| Screen | Contents |
|---|---|
| Start | **Sign in with Railway** (prominent) and **Try with sample data**. After a failed sign-in, the message shows in red with a symbol, and **Try again** is the prominent button. A build with no OAuth client ID offers only sample data and says why. |
| Workspace list | After a sign-in with several shared workspaces: **Choose a workspace** and one row for each workspace. With no shared workspace: a message and **Sign in again**. |
| Projects | Top bar: **Refresh** and **Settings**. Each project: a **Manage** menu and an **Add service** row. Bottom bar: **New project** and **Quit Topway**. |
| Usage | Opens from **Usage and cost**, the first row of the projects list. Shows the cost that Railway gives, the billing period, the limits and the use of each resource. Bottom bar: **Refresh**. |
| Environments | Opens from the project **Manage** menu. Each row: **Delete…**. Bottom bar: **New environment**, which opens a form with **Name** and **Copy from**. |
| Service links | The services of one environment, each with **Uses** and **Used by** lines and the variable names. A missing target shows **Service not found** with a triangle. It is a list, not a drawing, because a list stays readable for 2 to 15 services and VoiceOver reads each link as a sentence. Top: an **Environment** menu. Bottom bar: **Refresh**. |
| Add service | A segmented control for the source: GitHub repository, Docker image or Database. A database shows a radio group of the four databases, and the environment. Bottom bar: **Cancel**, and **Add service** or **Add database**. |
| Service | The tabs **Variables**, **Deployments** and **Metrics**. A **Manage** menu for Settings, Domains, Redeploy and Delete service. |
| Service settings | A form with the name, the source as text, and one field for each setting of the environment. Bottom bar: **Save changes**, available only after a change. |
| Variables | Each row: **Show**, **Copy** and **Edit**. Below a value with references, each target shows with its status as text and a symbol. The targets are names, so they show also while the value is hidden. Bottom bar: **Copy all** and **Add variable**. |
| Edit variable | Below the value: an **Insert reference** menu (a service, then a variable) and, after `${{`, **Suggestions** as small bordered buttons. They are in the content, not in a bar, because they change the value. Bottom bar: **Delete variable…**, **Cancel** and **Save changes**. |
| Domains | Each row: the kind, the status as text with a symbol, **Copy** and **Delete…**. A custom domain also shows its DNS records, each with **Copy value**. Bottom bar: **Add Railway domain** and **Add custom domain**. |
| Deployments | Each row: **View logs**, **Open URL**, **Restart** and a **Manage** menu. Bottom bar: **Refresh** and **Redeploy**. |
| Metrics | One chart for each metric, with the latest and the highest value as text. Bottom bar: a **Time range** menu and **Refresh**. |
| Logs | Back button: **Deployments**. Bottom bar: the connection state and **Copy logs**. |
| Settings | The **Account** section has the name and email of the signed-in user, a **Workspace** picker, and **Sign out…** with a confirmation in the same window. All settings apply at once. |

## Welcome window

Topway has no Dock icon, so at launch a new user sees nothing. At the first launch, the **Welcome to Topway** window (`topway/App/Welcome`) shows four pages. They tell what Topway does and where the menu bar icon is. The window does not show again.

The window has the style of the App Store screenshots of Topway. On the leading side, a large headline and a message are on a warm stone ground. On the trailing side, a flat stone stage holds a copy of a part of Topway.

| Page | Copy on the stage | Headline | Message |
|---|---|---|---|
| 1 | The projects list with the sample projects | **Welcome to Topway** | What Topway is. It is in the menu bar, not in the Dock. |
| 2 | The menu bar with the Topway icon in each state: **Healthy**, **In progress**, **Failed** | **See the health of your services** | The icon shows the health. Alerts are in Settings. |
| 3 | The Deployments tab of a sample service, with **View logs**, **Restart** and **Manage** in each row | **Work from the menu bar** | Restart, redeploy, variables, live logs. The confirmation and the production label. |
| 4 | The menu bar with the selected Topway icon, and the start screen below the icon | **Find Topway in the menu bar** | Where to click, and **Sign in with Railway** or **Try with sample data**. |

The last page also has the hint for a full menu bar ("If you cannot see the icon…") and the line "Topway collects no data." (see [PRIVACY.md](PRIVACY.md)). They are text on the ground, not a card.

### The copies of the app

- The copies are not image files and not drawings. They are the views of the app (`ProjectRow`, `SpendRow`, `ScreenHeader`, `ServiceMenu`, `ServiceContextBar`, `DeploymentRow`, `MenuBarLabel`, `SettingsButton`, `ActionBar`, `ScreenLayout`) with the data of a new `SampleDataSource` (`WelcomeSample`). They are sharp at each scale, they change when the app changes, and they show no data of the user.
- The welcome window does not make an `AppState`, because `AppState.init` changes the Keychain and `UserDefaults`. `ProjectsHeader` and `StartView` read `AppState`, so `FragmentProjectsHeader` and `StartFragment` copy their parts. If you change one of these views, change its copy too.
- The icon states on page 2 come from the sample projects and the rule of `HealthSummary`, so they are always the symbols of `MenuBarLabel`.
- A copy is a picture. It does not take clicks (`allowsHitTesting(false)`) or keyboard focus (`focusable(false)`). VoiceOver reads it as one image with a short description (`WelcomePage.pictureDescription`). The element ignores its children, so VoiceOver does not offer the buttons of the copy as actions.
- A copy has the true width of the menu bar window (360 points). The stage cuts it at the bottom edge, and cuts the copy of the menu bar at the trailing edge, as the edge of the screen. Only the copy of the current page is on the stage.

### Controls and keys

- The bottom bar has the page indicator on its own row, so it does not move. Below it are **Skip** (not on the last page), **Back** (not on the first page) and **Continue**. On the last page, **Continue** changes to **Done**. **Skip** and **Done** close the window.
- Return selects **Continue** or **Done**. Escape selects **Skip**. The Left Arrow and Right Arrow keys go to the previous and the next page. The pages take the keyboard focus (`focusable(interactions: .edit)`), so the arrow keys work also when Full Keyboard Access is off.
- **Skip** and **Back** use `.glass`. **Continue** and **Done** use `.glassProminent` with the `ink` tint: a dark button on the light ground, and a light button in the dark appearance. The system gives the label a color that contrasts. The three buttons are in one `GlassEffectContainer`. The copies keep the glass buttons of the app bars, but the welcome window adds no glass to its content.
- VoiceOver: each headline is a header. When the page changes, the VoiceOver focus goes to the new headline. The page indicator reads "Page 2 of 4". The pages that do not show are hidden.
- Motion: the old text moves out and the new text moves in, by 36 points, with `Animation.screenChange`. The copy on the stage fades. With Reduce Motion, the text only fades. The ground and the stage do not move.

### Size and type

The sizes are in `WelcomeLayout`, not in `Layout`.

- The window has no title bar (`.hiddenTitleBar`), so the ground fills it. The user can move the window with a drag on its background (`windowBackgroundDragBehavior`).
- The size is fixed. The content is 780 × 456 points, and macOS keeps the title bar area (32 points) above it, so the window is 780 × 488 points (16:10).
- The text column is 288 points wide, 40 points from the leading edge.
- The stage starts 40 points after the text and 40 points below the top of the window, and goes to the trailing and bottom edges. A 45° cut of 32 points removes its top leading corner. The copy is 28 points inside the stage. The capitals of the headline are level with the top of the copy.
- The headline is the system font at 34 points, semibold, with a tracking of −1 point (about −0.03 em) and a line height of 1.0. It has two lines or fewer. The message uses `.title3`, and the notes use `.body`. The text in the copies has the sizes of the app.

### Colors of the welcome window

The window uses neutral colors only (`WelcomePalette`, made of `WelcomeColor` values). It has no gradient, no shadow at rest, no glow and no glass on its content. The only other colors come from the copies of the app: the system blue and the status colors. The colors follow the appearance:

| Color | Light | Dark | Use |
|---|---|---|---|
| `ground` | `#ECEBE7` | `#1B1A18` | The background of the window. |
| `stage` | `#D5D2CA` | `#2A2926` | The stage. |
| `ink` | `#151513` | `#F1F0EC` | The headline, the dot of the current page, and the tint of **Continue** and **Done**. |
| `text` | `#3A3935` | `#B9B6AE` | The message and the notes. With Increase Contrast, it is `ink`. |
| `dot` | `#7A776F` | `#7A776F` | The dots of the other pages. With Increase Contrast, it is `text`. |

- The copies are dark in the two appearances, as in the screenshots. Their fill is `#202020` with a thin white edge at 16% opacity (50% with Increase Contrast), as the edge of a dark window. On the dark stage, the step to the darker copy and this edge keep the copy apart. There is no shadow.
- All fills are opaque, so Reduce Transparency changes nothing on the content. The system changes the glass of its button styles.

Contrast (WCAG 2.2: text needs 4.5:1, a dot needs 3:1). The values are calculated from the colors, and the preview renders of the four pages give the same colors.

| Pair | Light | Dark |
|---|---|---|
| Headline (`ink`) on `ground` | 15.33:1 | 15.25:1 |
| Message and notes (`text`) on `ground` | 9.69:1 | 8.58:1 |
| Message and notes with Increase Contrast (`ink`) | 15.33:1 | 15.25:1 |
| Label of **Continue** and **Done** on its fill, measured on the renders | 16.92:1 | 17.47:1 |
| Dot of another page (`dot`) on `ground` | 3.75:1 | 3.89:1 |
| The same with Increase Contrast (`text`) | 9.69:1 | 8.58:1 |
| White text of the copies on `#202020` | 16.29:1 | 16.29:1 |
