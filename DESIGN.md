# Design

This document gives the design rules of the Topway menu bar window. Read it before you change a screen.

## Problem

A user tested the first design and found two problems:

- Actions were hidden. Some actions showed only when the pointer was on a row. Other actions were in a menu behind an icon.
- Icons had no text. The user could not know what a click on "+", the trash can or the circle arrows did. The same arrow icon meant Refresh, Restart and Redeploy.

## Direction

Topway uses **native SwiftUI controls with text labels**. Liquid Glass comes from the system button styles, and only on the control layer. Topway does not draw custom glass controls.

The reasons:

- Apple says to use standard components, because they get Liquid Glass and its accessibility behavior automatically. See [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass).
- Apple says to use custom Liquid Glass effects sparingly and not in the content layer. See [Materials](https://developer.apple.com/design/human-interface-guidelines/materials).
- A text label says what a button does. An icon alone does not. See [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons).
- Standard controls are fast. The system draws them, and they need no hover state in each row.

The direction that was not selected is a custom design with `glassEffect` on rows and panels. It puts glass in the content layer, costs more to draw in a list, and needs custom work for each accessibility setting.

## Window

- The window is a `MenuBarExtra` with the `.window` style. The Human Interface Guidelines prefer a menu for a menu bar extra, unless the function is too complex for a menu. Topway edits variables, shows live logs and asks the user to type a name, so a menu cannot hold it. See [The menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar#Menu-bar-extras) and [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra).
- The size is fixed: **360 × 480 points** (`Layout.windowWidth`, `Layout.windowHeight`). The first design was 320 × 400. Text labels need the width. A fixed size keeps the window stable when the content changes.
- Settings is the native `Settings` scene, in its own window.

### Welcome window

Topway has no Dock icon, so at launch a new user sees nothing. At the first launch, the **Welcome to Topway** window (`topway/App/Welcome`) shows a short onboarding of four pages. It tells what Topway does and where the menu bar icon is. It does not show again.

| Page | Picture | Heading | Message |
|---|---|---|---|
| 1 | The app icon | **Welcome to Topway** | What Topway is. It is in the menu bar, not in the Dock. |
| 2 | The three menu bar icons: **Healthy**, **In progress**, **Failed** | **See the health of your services** | The icon shows the health. Alerts are in Settings. |
| 3 | A copy of the live logs, and in front of it a copy of the restart confirmation in production | **Work from the menu bar** | Restart, redeploy, variables, live logs. The confirmation and the production label. |
| 4 | The menu bar with the Topway icon, and the start screen below the icon | **Find Topway in the menu bar** | Where to click, and **Sign in with Railway** or **Try with sample data**. |

- The last page also has the hint for a full menu bar ("If you cannot see the icon…", in a card) and the line "Topway collects no data." (see [PRIVACY.md](PRIVACY.md)).
- The pictures are SwiftUI views, not image files. The icon in the menu bar picture is `MenuBarLabel`. The health picture uses the symbols of `MenuBarLabel`. If you change a symbol there, change it in `HealthStatesHero` too. The copies of the app use the texts of the app and of the sample data.
- The bottom bar has **Skip** (not on the last page), the page indicator, **Back** (not on the first page) and **Continue**. On the last page, **Continue** changes to **Done**. **Skip** and **Done** close the window.
- Return selects **Continue** or **Done**. Escape selects **Skip**. The Left Arrow and Right Arrow keys go to the previous and the next page. The pages take the keyboard focus (`focusable(interactions: .edit)`), so the arrow keys work also when Full Keyboard Access is off.
- The window has no title bar (`.hiddenTitleBar`), so the gradient fills it. The user can move the window with a drag on its background (`windowBackgroundDragBehavior`).
- The width is fixed: 560 points (`WelcomeLayout.windowWidth`). All pages are in one stack, so the height is the height of the tallest page, and it does not change when the page changes. A larger text makes the window taller, and no text clips. The user cannot change the size. The sizes are in `WelcomeLayout`, not in `Layout`.
- The heading of each page uses `.largeTitle` with the bold weight, the message `.title3`, and the notes `.callout`. The text in the copies of the app has small fixed sizes, as in an image.
- VoiceOver: each heading is a header. When the page changes, the VoiceOver focus goes to the new heading. The page indicator reads "Page 2 of 4". The pages that do not show are hidden. The health picture reads what each icon means. The other pictures are hidden, because the page text gives the same information.

#### Colors of the welcome window

- The background is a `MeshGradient` of the brand colors of the app icon (`Appicon.icon`): `#5E17EB`, `#8205FF` and `#B300FF` at the top, and darker violets below, down to `#1F0866`. It does not move. `WelcomePalette` has the colors.
- The colors are fixed. They do not change with the appearance. The window uses the dark appearance for its controls and its text in all system appearances.
- All text is white. This is the one exception to the rule "do not put white text on a system color" (see "Type, color and space"). The brand colors are not system colors, so they do not change with Increase Contrast, and white text on them keeps its contrast.
- With Increase Contrast, all colors of the mesh are 28% darker, and the borders and the page dots are brighter.
- The copies of the app are on a deep violet fill (`WelcomeSurface`, `#130540`) at 60% opacity with a thin white border. A copy in front of another copy is opaque. With Reduce Transparency, all fills are opaque.

Contrast of white text (WCAG 2.2, minimum 4.5:1):

| Background | White text |
|---|---|
| `#B300FF`, the lightest color, at the top trailing corner. No text is on it. | 4.82:1 |
| `#8205FF` | 6.15:1 |
| `#5E17EB` | 7.50:1 |
| `#1F0866`, the darkest color | 16.35:1 |
| Any mix of the mesh colors. The mesh mixes in straight lines (`smoothsColors: false`), so a mix is never lighter than the lightest color in each channel. | at least 4.68:1 |
| The gradient behind the heading, the message and the notes, measured on the preview renders of the four pages | at least 6.09:1 |
| The same with Increase Contrast | at least 8.91:1 (calculated: at least 7.79:1) |
| The fill of the copies at 60%, on `#B300FF` | 11.92:1 |
| The opaque fill | 18.69:1 |

- The red **Production environment** text (`#FF453A`) is only on the opaque fill: 5.49:1.
- A page dot that is not current is white at 50% opacity (80% with Increase Contrast): 4.15:1 on the bottom of the gradient. A dot needs 3:1.

## Layout

Each screen has the same parts, from top to bottom. `ScreenLayout` puts them together.

| Part | Contents | Component |
|---|---|---|
| Sample data banner | Shows on all screens in sample mode. | `SampleDataBanner` |
| Incident banner | Shows on all screens while Railway reports an open incident. The user can hide it. | `IncidentBanner` |
| Top bar | A back button with the name of the earlier screen, the title, and at most one control. | `ScreenHeader`, `ProjectsHeader` |
| Context | What the content belongs to: the project, the environment, the tabs. | `ServiceContextBar` |
| Content | A list, a form, or one state: loading, empty or error. | See "States". |
| Error message | The error of a failed action. The content stays visible. | `ErrorBanner` |
| Bottom bar | A short status on the leading side. The actions of the screen on the trailing side. | `ActionBar` |

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
3. Put the actions of a screen in the bottom bar. At most one is prominent (`.glassProminent`). It is the action that the user does most.
4. Put the actions of a row in the row, as small bordered buttons.
5. Use a menu only for the rare actions of one item, and give the menu a text label. The label is **Manage**. The project menu has Add service, Environments, Service links, Mute alerts and Delete project. The service menu has Settings, Domains, Redeploy and Delete service. The menu of a deployment has Roll back, Cancel deployment and Remove deployment, and it shows only the actions that the deployment permits. The primary action is also visible outside the menu.
6. Put a destructive action last, after a divider. Its label ends with "…" when a confirmation follows. Its text is red. A menu item gets red text from `role: .destructive`. A bordered button needs `.foregroundStyle(.red)` too, because the role alone does not change its color on macOS.
7. Each action that changes data goes through `appState.confirm`. `GlassConfirmationDialog` shows in the window. Do not use `alert`, `confirmationDialog` or a sheet, because they close the menu bar window.
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

Use these system controls directly: `Button`, `Menu`, `Picker` (segmented for 2 or 3 tabs, menu for a list of environments or time ranges, radio group for a short list of options in a form), `Toggle`, `TextField`, `ContentUnavailableView` for an empty state, and `Form` in Settings.

## Liquid Glass

- Glass is only on the control layer: the buttons of the top bar and the bottom bar (`.buttonStyle(.glass)`, `.glassProminent`), the **Follow new lines** button on the logs, the bottom bar of the welcome window, and the card of the confirmation dialog (`glassEffect`).
- In the welcome window, **Skip** and **Back** use `.glass`. **Continue** and **Done** use `.glassProminent` with a white tint, because the accent color is not clear on the purple gradient. The three buttons are in one `GlassEffectContainer`. The copies of the app on the pages do not use glass, because they are content.
- Never put glass on a list row, on a form field or on a panel of content.
- Put the glass buttons of one bar in one `GlassEffectContainer`. The system then draws them in one pass. See [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer).
- Do not put glass on glass. The buttons in the dialog card use `.bordered` and `.borderedProminent`.
- With Reduce Transparency, the dialog card is opaque. The system changes the glass of its own button styles.
- The bars are above and below the content, not on it (`ScreenLayout` is a `VStack`). The content is clipped between the bars, so no row can scroll under a bar and show through its text. Do not use `safeAreaBar` or `safeAreaInset` for a bar: a scroll view then goes under the bar, and on macOS the rows can show through it.
- For the rules of the effect, see [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views).

## Type, color and space

- Use the system text styles: `.headline` for a screen title, `.body` for a row title, `.callout` for context and messages, `.subheadline` for a status or a date. Use a monospaced design for variable names, variable values and log lines.
- Use `.fontWeight(.medium)` only for the main text of a row.
- Use `.title` with the semibold weight only for the one number that a screen is about, such as the cost on the usage screen.
- Use the hierarchical styles `.secondary` and `.tertiary` for less important text and icons. Do not set an opacity on text.
- Color has a meaning: orange for sample data and warnings, red for errors, destructive buttons and destructive confirmations, green, yellow, red, purple and gray for the deployment status, and the accent color for the prominent button. A color is never the only sign: a text or a symbol is always with it.
- Do not put orange text on a tint, and do not put white text on a system color. The system colors change with Increase Contrast, and such text is then hard to read. Color the symbol, or use red text with a symbol. The welcome window is the exception: its gradient has fixed brand colors, and its text is white (see "Colors of the welcome window").
- Icons in rows are monochrome.
- A chart (`MetricCard`, Swift Charts) is content: it has no glass, no axis and one series in the tint color. The values that matter are text next to the chart, so the chart is never the only way to read a value. The chart height is `Layout.chartHeight`.
- Use the constants of `Layout` for padding and spacing.

## Motion

- One animation: `Animation.screenChange` (ease in and out, 0.2 seconds). It is for a change of screen, a project that opens or closes, and the dialog.
- A screen one level down moves in from the trailing edge. With Reduce Motion, it only fades (`AnyTransition.screen(reduceMotion:)`).
- Each custom animation and transition reads `accessibilityReduceMotion`. With Reduce Motion, a project opens and closes with no animation, and the dialog only fades.
- In the welcome window, the old page moves out and the new page moves in, by 36 points, with `Animation.screenChange`. With Reduce Motion, the pages only fade. The gradient does not move.
- The incident banner shows and hides with no animation.
- No animation on hover. No animation that repeats. The only timer is the 2 seconds of `CopyButton`.

## States

| State | Content |
|---|---|
| First load | `LoadingStateView` with a text, for example "Loading projects…". |
| Reload | The list stays. The Refresh button is not available until the load ends. |
| Empty | `ContentUnavailableView` that says what is missing and which button adds it. |
| Load failed | `ErrorStateView`. The title says what did not load. The buttons come from `RecoveryRules`. |
| Action failed | `ErrorBanner` above the bottom bar. |

When Railway does not accept the token, `ErrorStateView` shows **Sign in again** and **Try with sample data**, and no retry. Settings has **Sign out…**, which shows the start screen again. In sample mode, the sample data stays until the user exits it, and then the start screen shows.

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
- [docs/accessibility.md](docs/accessibility.md) has the evaluation for the App Store labels and the manual checks. Do the evaluation again when you change a screen.
- Symbols that only decorate are hidden from VoiceOver. A hidden value reads as "Hidden value".
- The system controls support Full Keyboard Access, Increase Contrast and Reduce Transparency.
- Escape goes back. Return adds a service from its text field. Command-Return saves a variable or the service settings. Command-R refreshes the projects.

## Performance

- Lists use `ScrollView` with `LazyVStack`.
- No glass effect in a row. A screen has at most 6 glass shapes.
- A row has no hover state for its actions. Only `RowButtonStyle` keeps a hover flag, in the row that the pointer is on.
- A reload keeps the list on the screen. Only the first load shows a progress indicator.
- Views read only the `AppState` properties that they show, so a change updates only those views.

Tradeoffs:

- The content does not scroll under the bars, so the window has no scroll edge effect. A row stops at the edge of a bar. The first design put the content under the bars with `safeAreaBar`, but the rows showed through the bar text after a change of screen.
- `Deployment.formattedDate` makes date formatters on each call. The deployments list is short, so this stays.
- Rows are taller than in the first design, because their actions are always visible. The window is 80 points taller to keep the number of visible rows.

## Screens

| Screen | First design | This design |
|---|---|---|
| Projects | "+" and trash icons on each project, a gear, a "+" in the section header. | **Refresh** and **Settings** in the top bar. **Manage** menu and an **Add service** row in each project. **New project** and **Quit Topway** in the bottom bar. |
| Usage | No usage. | The row **Usage and cost** is first in the projects list. The screen shows the cost that Railway gives, the billing period, the limits and the use of each resource. **Refresh** in the bottom bar. |
| Environments | No environment actions. | The **Manage** menu of a project opens the list. A **Delete…** button in each row. **New environment** in the bottom bar opens a form with **Name** and **Copy from**. |
| Service links | No links. | A list of the services of one environment. Each service shows **Uses** and **Used by** lines with the variable names, and **Service not found** with a triangle for a missing target. A list, not a drawing, because it stays readable for 2 to 15 services in the window and VoiceOver reads each link as a sentence. An **Environment** menu at the top and **Refresh** in the bottom bar. |
| Welcome | No window at launch. The user saw only the menu bar icon, and a full menu bar can hide it. | One window at the first launch: four pages on the brand gradient about what Topway does, the health icons, the actions, and where the icon is, with a hint for a full menu bar. **Skip**, **Back**, **Continue** and **Done** in the bottom bar. |
| Start | Shows only with no token. | **Sign in with Railway** (prominent) and **Try with sample data**. After a failed sign-in, the message shows in red with a symbol, and the prominent button is **Try again**. A build with no OAuth client ID offers only sample data and says why. A rejected token has a way back to it. |
| Workspace list | No list. The user typed a Workspace ID. | After a sign-in with several shared workspaces: **Choose a workspace** and one row for each workspace. With no shared workspace, a message and **Sign in again**. |
| Service | Variables first. Deployments in a menu behind an icon. | Tabs **Variables**, **Deployments** and **Metrics**. **Manage** menu for Settings, Domains, Redeploy and Delete service. |
| Service settings | No settings. | A form with the name, the source as text, and one field for each setting of the environment. **Save changes** in the bottom bar is available only after a change. |
| Variables | Edit, show and copy icons that show on hover. | **Show**, **Copy** and **Edit** buttons in each row. A value with references shows each target below it, with its status as text and a symbol. The targets are names, so they show also while the value is hidden. **Copy all** and **Add variable** in the bottom bar. |
| Edit variable | Trash icon in the top bar. | **Delete variable…**, **Cancel** and **Save changes** in the bottom bar. Below the value, an **Insert reference** menu (a service, then a variable) and, after `${{`, **Suggestions** as small bordered buttons. Both are in the content, not in a bar, because they change the value. |
| Domains | No domains. | One row for each domain, with its kind, its status as text with a symbol, and **Copy** and **Delete…**. A custom domain shows its DNS records, each with **Copy value**. **Add Railway domain** and **Add custom domain** in the bottom bar. |
| Deployments | Logs and restart icons that show on hover. | **View logs**, **Open URL** and **Restart** buttons in each row, and a **Manage** menu for Roll back, Cancel deployment and Remove deployment. **Refresh** and **Redeploy** in the bottom bar. |
| Metrics | No metrics. | One chart for each metric, with the latest and the highest value as text. A **Time range** menu and **Refresh** in the bottom bar. |
| Logs | Back icon. | Back button **Deployments**. The connection state and **Copy logs** in the bottom bar. |
| Add service | Custom source buttons. | A segmented control for the source: GitHub repository, Docker image or Database. A database shows a radio group of the four databases and the environment. **Cancel** and **Add service** or **Add database** in the bottom bar. |
| Settings | Save at the bottom of all sections. No way to remove a token. | The **Account** section: the name and email of the signed-in user, a **Workspace** picker, and **Sign out…** with a confirmation in the same window. All settings apply at once. |

## Sources

- [Human Interface Guidelines: The menu bar, Menu bar extras](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar#Menu-bar-extras)
- [Human Interface Guidelines: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Human Interface Guidelines: Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)
- [Human Interface Guidelines: Pull-down buttons](https://developer.apple.com/design/human-interface-guidelines/pull-down-buttons)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
- [glassEffect(_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))
- [GlassButtonStyle](https://developer.apple.com/documentation/swiftui/glassbuttonstyle)
