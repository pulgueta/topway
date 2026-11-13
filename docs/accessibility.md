# Accessibility

This page tells you how Topway works with the accessibility features of macOS. It is also the accessibility URL of Topway in App Store Connect, and the checklist for contributors:
`https://github.com/pulgueta/topway/blob/main/docs/accessibility.md`

## For users

Topway uses the standard controls of macOS, and each action has a text label.

- **VoiceOver**: Each button, field and status has a name. VoiceOver says an error when it shows. In a confirmation, VoiceOver stays in the dialog.
- **Voice Control**: Say the text that you see on a button, for example "Click Restart". When more than one button has the same text, say "Show numbers".
- **Keyboard**: Escape goes back one step or cancels a dialog. Command-Return saves a variable or the service settings. Command-R refreshes the projects. In the welcome window, Return selects **Continue** or **Done**, Escape selects **Skip**, and the Left Arrow and Right Arrow keys change the page.
- **Dark appearance**: Topway follows the appearance of macOS.
- **Color**: A color is never the only sign of a status. A text or a symbol is always with it.
- **Contrast**: Topway uses the system colors. They change when you turn on Increase Contrast.
- **Motion**: With Reduce Motion, screens and dialogs fade. They do not move or change size.
- **Transparency**: With Reduce Transparency, the confirmation dialog has an opaque background.

Topway has no video and no audio, so it has no captions and no audio descriptions. The App Store label Larger Text is not available on Mac.

If something does not work for you, please tell us. Select **Settings > Help > Report a problem**, or [open an issue](https://github.com/pulgueta/topway/issues/new/choose).

## For contributors

When you change a screen, follow the rules below, do the [manual checks](#manual-checks) again, and record the result.

### Rules for new screens

[DESIGN.md](../DESIGN.md#accessibility-and-keyboard) has all the rules. The short list:

- [ ] Each control has a text label. If the accessibility label has more words than the visible text, `accessibilityInputLabels` has the visible text first.
- [ ] A button that shows in each row names its item in the accessibility label.
- [ ] No status shows by color only.
- [ ] Each custom animation and transition reads `accessibilityReduceMotion`.
- [ ] A result that shows away from the control, such as an error, posts an announcement.

### App Store labels

Apple permits a label only when the user can complete all common tasks with that feature. See the [overview of Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels).

The maintainer did the manual checks on a running app on 2026-11-12, and all checks passed. The recommendations come from the code and from these checks. **The welcome window changed after these checks** (the neutral style of 2026-11-13), so do checks 1 and 3 on it again.

| Label (Mac) | Recommendation | Reason |
|---|---|---|
| VoiceOver | Declare. | Each control has a name, a type and a value. Check 1 passed: the menu bar window, the row groups and the dialog work. |
| Voice Control | Declare. | Each action is a standard control with a name that includes the visible text. Check 2 passed. |
| Dark Interface | Declare. | The code has no fixed light color and no appearance override. Check 6 passed. |
| Differentiate Without Color Alone | Declare. | Each status has a text or a symbol with its color. Check 7 passed. |
| Sufficient Contrast | Declare. | Some colored text is below 4.5:1 in the light appearance by default (see [Known limits](#known-limits)). Apple permits the label when Increase Contrast gives sufficient contrast in an app that uses the Apple frameworks. Check 4 passed. |
| Reduced Motion | Declare. | Each custom animation fades or stops with Reduce Motion. Check 5 passed. |
| Larger Text | Not available on Mac. | Apple does not offer this label for Mac apps. |
| Captions | Not applicable. Do not select it. | Topway has no video and no audio. |
| Audio Descriptions | Not applicable. Do not select it. | Topway has no video. |

Do the evaluation again for each release that changes a screen.

### Common tasks

Each check must work for all of these tasks:

- First launch: the welcome window, **Skip**, **Back**, **Continue** and **Done**.
- Open Topway from the menu bar and read the health.
- The start screen: **Sign in with Railway**, **Try again**, **Try with sample data** and **Exit sample data**. Choose a workspace after the sign-in.
- Settings: **Account**, **Workspace**, **Sign out…**, auto refresh, alerts, launch at login and Help.
- See the projects, open or close a project, **Refresh**, and mute alerts.
- **Usage and cost**: the cost, the period, the limits and **Refresh**.
- Open a service, change the environment and change the tab.
- Variables: **Show**, **Copy**, **Copy all**, the targets of references and their status. Add, edit and delete a variable, with **Insert reference** and **Suggestions**.
- Service settings, domains and their DNS records, and environments.
- Deployments: **View logs**, **Open URL**, **Restart**, **Redeploy**, and the **Manage** menu.
- Metrics, logs (tabs, follow, **Copy logs**, **Retry**) and service links.
- Add a service or a database. Delete a project or a service (type the name).
- The Railway incident banner: **Open status page** and **Hide**.
- Error states, empty states and notifications.
- **Quit Topway**.

### How Topway meets each label

#### VoiceOver and Voice Control

- **Standard controls.** All actions are `Button`, `Menu`, `Picker`, `Toggle`, `TextField`, `SecureField`, `TextEditor` and `Link`. Settings is a `Form`, and empty states are `ContentUnavailableView`. The system gives these controls their type, their value and their keyboard use. Topway has no custom control and no custom text entry.
- **No hover-only actions.** `RowButtonBody` uses hover only for a highlight. The only action with no control is a click on the dialog backdrop, and **Cancel** does the same.
- **Menu bar icon.** `MenuBarLabel` reads "Topway", "Topway, build or deploy in progress" or "Topway, 2 services failing". The words come from `HealthSummary.statusDescription`, with tests in `HealthSummaryTests`.
- **Rows.** A row is a group with the name of its item, and each button in it names the item:
  - `ProjectRow` has the value "Expanded" or "Collapsed", with "alerts muted" for a muted project. **Add service** reads "Add service to" and the project name.
  - `ServiceRow` reads the service name, not the names of its symbols.
  - A **Manage** menu reads "Manage" and the name of its item. In `DeploymentRow`, it reads "Manage" and the status and date of the deployment.
  - `VariableRow` and `DeploymentRow` buttons read, for example, "Copy value of DATABASE_URL" and "Restart, Running, 11/10/26, 10:00". A sealed variable has no **Show** and no **Copy**.
  - `EnvironmentRow`, `DomainRow` and `DNSRecordRow` name their environment, domain or record, for example "Copy value of CNAME record shop".
  - `ReferenceSuggestions` is a group with the label "Suggestions". Each button reads "Insert reference to postgres.DATABASE_URL". **Insert reference** is a standard `Menu` with a submenu for each service.
  - `ReferenceLinkRow` reads "Reference to postgres.DATABASE_URL: Found" (`ReferenceLink.accessibilityDescription`, tested). It has names only, so it never reads a hidden value.
  - `ServiceLinkSection` reads each link as a sentence with names only, for example "worker uses billing in BILLING_URL. The project has no service with this name." (`ServiceGraph.sentence(for:)`, tested). The arrow symbols are not read.
- **Voice Control names.** Where the label has more words than the visible text, `accessibilityInputLabels` gives the visible text first: "Manage", "Add service", "Show", "Copy", "Edit", "View logs", "Open URL", "Restart", "Delete", "Copy value", "Hide", the name on the back button, and each suggestion.
- **Headers and back.** The title of each screen and of the dialog has the header trait. The back button reads "Back to" and the name of the screen.
- **Hidden and spoken states.** Symbols that only decorate are hidden, for example the status dot of a deployment and the dialog backdrop. A hidden value reads "Hidden value", and a sealed value reads "Sealed value". A log line reads "Warning:" or "Error:" and the message. `LogConnectionLabel` reads "Connection: Live". Each progress indicator has a label, for example "Loading projects".
- **Announcements.** `ErrorBanner` and `ErrorStateView` announce an error when it shows, but only while the window is open. When the window opens again, VoiceOver says the error that shows. The start screen announces the error of a failed sign-in, or why the sign-in ended, in the same way. `CopyButton` announces "Copied", the service settings announce "Saved", and the variable editor announces "Suggestions are below the value."
- **Confirmation dialog.** `destructiveConfirmation` disables the content behind the dialog and hides it from assistive technologies. The card has the modal trait. The keyboard focus goes to the name field, or else the VoiceOver focus goes to the title. **Cancel** has the Escape shortcut, and Return confirms only an action that is not destructive. Voice Control can dictate into the name field.
- **Keyboard.** `onExitCommand` in `MainView`, `ServiceView`, `AddServiceView`, `EnvironmentsView`, `NewEnvironmentView`, `NewDomainView` and `ServiceLinksView` goes back one step.
- **Charts and usage.** `MetricCard` reads the name, the latest value and the highest value as one item, and hides the chart, which only shows the trend of the same values. `SpendSummary` reads the cost, its period and the days left as one item. The limit bar reads the limit amounts and, for example, "50 percent of the limit".
- **Incident banner.** `IncidentBanner` is a group with the label "Railway incident". It announces each incident one time, because it shows with no user action. An incident that starts while the window is closed is said when the window opens.
- **Welcome window.** Each headline is a header, and the VoiceOver focus goes to the new headline when the page changes. The page indicator reads "Page 2 of 4", and the pages that do not show are hidden. Each copy of the app is one image with a short description. Its buttons take no clicks and no focus (`focusable(false)`), so VoiceOver, Voice Control, Tab and Space do not get to them. A test on all four pages confirmed this. The arrow keys change the page also when Full Keyboard Access is off.

#### Dark Interface

All colors are system colors, hierarchical styles (`.secondary`, `.tertiary`), the tint and system materials. The only fixed color is the black backdrop of the dialog at 30% opacity, which is dark. No view sets `preferredColorScheme`. The welcome window has its own neutral colors, each with a light and a dark value (`WelcomePalette`). Its copies of the app are dark in the two appearances, as pictures.

#### Differentiate Without Color Alone

| Item | Sign other than color |
|---|---|
| Menu bar health | Three symbols: tram, arrows, warning triangle. On welcome page 2, also the text **Healthy**, **In progress** and **Failed**. |
| Sample data | The text "Sample data" and a symbol. |
| Muted project, open project | A bell with a line. The direction of the chevron. |
| Deployment status | The status text next to the colored dot. |
| Log levels and connection | A triangle for a warning, an octagon for an error. A different symbol and text for each connection state. |
| Destructive actions | The word "Delete" or "Remove". The production label has the text "Production environment" and an octagon. |
| Errors and results | A symbol and a text, such as "Saved" or the error message. |
| Notifications | The title says the result, for example "Deployment failed". |
| Reference status | "Found" (check mark), "Service not found" and "Variable not found" (triangle), "Set by Railway" (circle with "i"), "Not checked" (question mark). In **Service links**, the words **Uses** and **Used by** give the direction. |
| Sealed variable | The text "Sealed" and a lock. |
| Form problems | Text below the field, with a warning triangle. The button of the form is then not available. |
| Domain status | "Set the DNS records" (triangle), "Railway makes the certificate" (clock), "Certificate failed" (octagon with a cross, and what to check), "Ready" (check mark). A DNS record shows "Set" (check mark) or "Not set" (clock). |
| Usage above the limit | Red text with an octagon and the words "The usage is above the limit." |

#### Sufficient Contrast

Text uses the system text styles and the system colors, which change with Increase Contrast. Names, values and info log lines use the primary color.

- `SampleDataBanner`, `IncidentBanner`, form problems and reference status keep their text in the primary color. Only the symbol or the background tint is orange.
- `GlassConfirmationDialog`: the production label is red text with a symbol, not white text on red.
- Welcome window: the headline is 15.33:1 (light) and 15.25:1 (dark) on the ground. The message and the notes are 9.69:1 and 8.58:1, and they take the color of the headline with Increase Contrast. [DESIGN.md](../DESIGN.md#colors-of-the-welcome-window) has all the numbers.

#### Reduced Motion and Reduce Transparency

Topway has one custom animation, `Animation.screenChange` (0.2 seconds).

- A screen change (`MainView`, `ServiceView`) only fades with Reduce Motion (`AnyTransition.screen(reduceMotion:)`).
- A project that opens or closes (`ProjectRow`) has no animation with Reduce Motion.
- The dialog (`destructiveConfirmation`) only fades with Reduce Motion, and does not change size.
- In the welcome window, the text of a page moves by 36 points and fades, and the copy fades. With Reduce Motion, the text only fades. The ground and the stage do not move.
- These have no animation: the scroll to the newest log line, the "Copied" text, the charts and the incident banner.
- The system controls the motion of the menu bar window, the Settings window, the progress indicators and the glass buttons.
- Topway has no parallax, no symbol effect, no animation that repeats, and no content that moves by itself, apart from new log lines. A scroll up stops them.
- With Reduce Transparency, the dialog card is opaque. All other glass comes from the system button styles, and the welcome window has only opaque fills.

### Known limits

- **Colored text in the light appearance.** By default, orange text (log warnings) is near 2.2:1 on a white background, and red text (log errors, destructive buttons, error messages) is near 3.6:1. The design keeps red text on destructive buttons. The system colors get darker with Increase Contrast, and check 4 must show that they are then sufficient.
- **White text on the red confirm button.** The system draws the prominent button of a destructive dialog. Check 4 must show its contrast in the two appearances.
- **Secondary text.** Dates, counts, hints and the **Add service** row use `.secondary`. The system makes it stronger with Increase Contrast.
- **Menu bar name for Voice Control.** The icon has no visible text, and its name changes with the health. "Click Topway" can fail when the health is not healthy. "Show numbers" always works.
- **No main menu.** Topway has no Dock icon and no visible main menu (`LSUIElement`). All actions are in the menu bar window and in Settings.

### Manual checks

Do each check in sample mode (**Try with sample data**) for all [common tasks](#common-tasks). Sample mode ends when you sign in, so do the account tasks (**Sign in with Railway**, the workspace list, **Settings > Account**, **Sign out…** and the rejected token screen) again with a Railway account. The sign-in page is a system browser window: check only that VoiceOver and Voice Control can get to it and back. A check passes when you can complete each task with only that feature.

1. **VoiceOver.** Press Command-F5. Press VO-M two times to go to the status menus, find Topway and press VO-Space. Move with VO-Right and VO-Left. Go into a row group with VO-Shift-Down.
   - VoiceOver says the name, the type and the value of each control.
   - The VoiceOver cursor goes into the window when it opens, and into the dialog when it shows.
   - In a dialog, you cannot get to the content behind it. Escape cancels.
   - VoiceOver says an error when an action fails. To make an error, turn off the network while you are signed in.
   - Do the same in the Settings window.
   - In the welcome window (delete the `welcomeWindowShown` key and launch), VoiceOver reads the headline, the message, the picture as one item, and the buttons. After **Continue**, it reads the new headline.
2. **Voice Control.** Turn it on in **System Settings > Accessibility > Voice Control**. Say "Show names", then "Show numbers".
   - Each button, menu, tab and field has a name and a number.
   - "Click Manage", "Click Restart", "Click Variables" and "Click Projects" work.
   - In the delete dialog, dictate the name into the field. The name must be exact.
   - "Scroll down" works in the lists and in the logs.
3. **Full keyboard.** Use only Tab, Space, Return, the arrow keys and Escape for each task.
4. **Increase Contrast.** Turn on **System Settings > Accessibility > Display > Increase contrast**. Do the check in the light and the dark appearance, then again with Reduce transparency on.
   - You can read all text, also orange, red and secondary text, and the label of the red confirm button.
   - Use the Accessibility Inspector of Xcode to measure text that you are not sure about. The minimum is 4.5:1.
5. **Reduce Motion.** Turn on **Display > Reduce motion**. Open a service, open the logs, go back, open a dialog, and open and close a project.
   - Screens and the dialog fade. No content moves across the window or changes size.
6. **Dark and Light.** Change **System Settings > Appearance**. Look at each screen, the dialog and Settings in the two appearances.
   - No screen shows a large light area in the dark appearance.
7. **Color.** Turn on **Display > Color filters > Grayscale**.
   - You can tell each status, each log level and each destructive action without color.
8. **Reduce Transparency.** Turn on **Display > Reduce transparency**. Open a dialog.
   - The dialog card is opaque, and you can read the bars above the lists.

Record the date, the macOS version and the result of each check in the pull request or the release notes.

## Sources

- [VoiceOver evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voiceover-evaluation-criteria)
- [Voice Control evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voice-control-evaluation-criteria)
- [Dark Interface evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/dark-interface-evaluation-criteria)
- [Differentiate Without Color Alone evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/differentiate-without-color-alone-evaluation-criteria)
- [Sufficient Contrast evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/sufficient-contrast-evaluation-criteria)
- [Reduced Motion evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)
