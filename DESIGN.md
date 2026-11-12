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

## Layout

Each screen has the same parts, from top to bottom. `ScreenLayout` puts them together.

| Part | Contents | Component |
|---|---|---|
| Sample data banner | Shows on all screens in sample mode. | `SampleDataBanner` |
| Top bar | A back button with the name of the earlier screen, the title, and at most one control. | `ScreenHeader`, `ProjectsHeader` |
| Context | What the content belongs to: the project, the environment, the tabs. | `ServiceContextBar` |
| Content | A list, a form, or one state: loading, empty or error. | See "States". |
| Error message | The error of a failed action. The content stays visible. | `ErrorBanner` |
| Bottom bar | A short status on the leading side. The actions of the screen on the trailing side. | `ActionBar` |

The bars are the control layer. The content is the content layer.

## Navigation

There is no `NavigationStack`. `MainView` and `ServiceView` each hold an enum of screens.

```text
Projects (start screen with no token)
├── Add service
└── Service: tabs Variables | Deployments | Metrics
    ├── Add variable / Edit variable
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
5. Use a menu only for the rare actions of one item, and give the menu a text label. The label is **Manage**. The project menu has Add service, Mute alerts and Delete project. The service menu has Redeploy and Delete service. The primary action is also visible outside the menu.
6. Put a destructive action last, after a divider. Its label ends with "…" when a confirmation follows. Its text is red. A menu item gets red text from `role: .destructive`. A bordered button needs `.foregroundStyle(.red)` too, because the role alone does not change its color on macOS.
7. Each action that changes data goes through `appState.confirm`. `GlassConfirmationDialog` shows in the window. Do not use `alert`, `confirmationDialog` or a sheet, because they close the menu bar window.
8. In a dialog, Return confirms only an action that is not destructive.

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

Use these system controls directly: `Button`, `Menu`, `Picker` (segmented for 2 or 3 tabs, menu for a list of environments or time ranges), `Toggle`, `TextField`, `ContentUnavailableView` for an empty state, and `Form` in Settings.

## Liquid Glass

- Glass is only on the control layer: the buttons of the top bar and the bottom bar (`.buttonStyle(.glass)`, `.glassProminent`), the **Follow new lines** button on the logs, and the card of the confirmation dialog (`glassEffect`).
- Never put glass on a list row, on a form field or on a panel of content.
- Put the glass buttons of one bar in one `GlassEffectContainer`. The system then draws them in one pass. See [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer).
- Do not put glass on glass. The buttons in the dialog card use `.bordered` and `.borderedProminent`.
- With Reduce Transparency, the dialog card is opaque. The system changes the glass of its own button styles.
- The bars use `safeAreaBar`. Content scrolls under a bar, and the system scroll edge effect keeps the bar readable. The logs use the hard edge style, because dense text under a bar is hard to read. See [safeAreaBar](https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:)) and [scrollEdgeEffectStyle](https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:)).
- For the rules of the effect, see [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views).

## Type, color and space

- Use the system text styles: `.headline` for a screen title, `.body` for a row title, `.callout` for context and messages, `.subheadline` for a status or a date. Use a monospaced design for variable names, variable values and log lines.
- Use `.fontWeight(.medium)` only for the main text of a row.
- Use the hierarchical styles `.secondary` and `.tertiary` for less important text and icons. Do not set an opacity on text.
- Color has a meaning: orange for sample data and warnings, red for errors, destructive buttons and destructive confirmations, green, yellow, red, purple and gray for the deployment status, and the accent color for the prominent button. A color is never the only sign: a text or a symbol is always with it.
- Do not put orange text on a tint, and do not put white text on a system color. The system colors change with Increase Contrast, and such text is then hard to read. Color the symbol, or use red text with a symbol.
- Icons in rows are monochrome.
- A chart (`MetricCard`, Swift Charts) is content: it has no glass, no axis and one series in the tint color. The values that matter are text next to the chart, so the chart is never the only way to read a value. The chart height is `Layout.chartHeight`.
- Use the constants of `Layout` for padding and spacing.

## Motion

- One animation: `Animation.screenChange` (ease in and out, 0.2 seconds). It is for a change of screen, a project that opens or closes, and the dialog.
- A screen one level down moves in from the trailing edge. With Reduce Motion, it only fades (`AnyTransition.screen(reduceMotion:)`).
- Each custom animation and transition reads `accessibilityReduceMotion`. With Reduce Motion, a project opens and closes with no animation, and the dialog only fades.
- No animation on hover. No animation that repeats. The only timer is the 2 seconds of `CopyButton`.

## States

| State | Content |
|---|---|
| First load | `LoadingStateView` with a text, for example "Loading projects…". |
| Reload | The list stays. The Refresh button is not available until the load ends. |
| Empty | `ContentUnavailableView` that says what is missing and which button adds it. |
| Load failed | `ErrorStateView`. The title says what did not load. The buttons come from `RecoveryRules`. |
| Action failed | `ErrorBanner` above the bottom bar. |

When Railway does not accept the token, `ErrorStateView` shows **Open Settings** and **Try with sample data**, and no retry. Settings has **Remove token…**, which shows the start screen again.

## Copy

- Write in ASD-STE100 Simplified Technical English: short sentences, active voice, one instruction in each sentence.
- A button label starts with a verb and names the object: **Add variable**, **View logs**, **Remove token…**.
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
- Escape goes back. Return adds a service from its text field. Command-Return saves a variable. Command-R refreshes the projects.

## Performance

- Lists use `ScrollView` with `LazyVStack`.
- No glass effect in a row. A screen has at most 6 glass shapes.
- A row has no hover state for its actions. Only `RowButtonStyle` keeps a hover flag, in the row that the pointer is on.
- A reload keeps the list on the screen. Only the first load shows a progress indicator.
- Views read only the `AppState` properties that they show, so a change updates only those views.

Tradeoffs:

- Content scrolls under the bars, so the system draws the scroll edge effect and the glass buttons above moving content. This costs more than opaque bars. If a profile shows dropped frames, change `ScreenLayout` to a `VStack` with dividers. No other file must change.
- `Deployment.formattedDate` makes date formatters on each call. The deployments list is short, so this stays.
- Rows are taller than in the first design, because their actions are always visible. The window is 80 points taller to keep the number of visible rows.

## Screens

| Screen | First design | This design |
|---|---|---|
| Projects | "+" and trash icons on each project, a gear, a "+" in the section header. | **Refresh** and **Settings** in the top bar. **Manage** menu and an **Add service** row in each project. **New project** and **Quit Topway** in the bottom bar. |
| Start | Shows only with no token. | The same screen. A rejected token now has a way back to it. |
| Service | Variables first. Deployments in a menu behind an icon. | Tabs **Variables**, **Deployments** and **Metrics**. **Manage** menu for Redeploy and Delete service. |
| Variables | Edit, show and copy icons that show on hover. | **Show**, **Copy** and **Edit** buttons in each row. **Copy all** and **Add variable** in the bottom bar. |
| Edit variable | Trash icon in the top bar. | **Delete variable…**, **Cancel** and **Save changes** in the bottom bar. |
| Deployments | Logs and restart icons that show on hover. | **View logs**, **Open URL** and **Restart** buttons in each row. **Refresh** and **Redeploy** in the bottom bar. |
| Metrics | No metrics. | One chart for each metric, with the latest and the highest value as text. A **Time range** menu and **Refresh** in the bottom bar. |
| Logs | Back icon. | Back button **Deployments**. The connection state and **Copy logs** in the bottom bar. |
| Add service | Custom source buttons. | A segmented control for the source. **Cancel** and **Add service** in the bottom bar. |
| Settings | Save at the bottom of all sections. No way to remove a token. | **Save** in the Credentials section. **Remove token…** with a confirmation in the same window. |

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
- [safeAreaBar(edge:alignment:spacing:content:)](https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:))
- [scrollEdgeEffectStyle(_:for:)](https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:))
