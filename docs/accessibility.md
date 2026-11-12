# Accessibility

This page tells you how Topway works with the accessibility features of macOS. It also records the evaluation for the Accessibility Nutrition Labels of the App Store.

You can use this page as the accessibility URL of the app in App Store Connect:
`https://github.com/pulgueta/topway/blob/main/docs/accessibility.md`

## For users

Topway is a menu bar app. It uses the standard controls of macOS, and each action has a text label.

- **VoiceOver**: Each button, field and status has a name. VoiceOver says an error when it shows. In a confirmation, VoiceOver stays in the dialog.
- **Voice Control**: You can say the text that you see on a button, for example "Click Restart". When more than one button has the same text, say "Show numbers".
- **Keyboard**: Escape goes back one step or cancels a dialog. Command-Return saves a variable. Command-R refreshes the projects.
- **Dark appearance**: Topway follows the appearance of macOS.
- **Color**: A color is never the only sign of a status. A text or a symbol is always with it.
- **Contrast**: Topway uses the system colors. They change when you turn on Increase Contrast.
- **Motion**: With Reduce Motion, screens and dialogs fade. They do not move or change size.
- **Transparency**: With Reduce Transparency, the confirmation dialog has an opaque background.

Topway has no video and no audio, so it has no captions and no audio descriptions. macOS does not have the Larger Text label.

If a feature does not work for you, tell us: select **Settings > Help > Report a problem**, or [open an issue](https://github.com/pulgueta/topway/issues/new/choose).

## Labels to declare

Apple permits a label only when the user can complete all common tasks with that feature. See the [overview of Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels).

The maintainer did the manual checks below on a running app on 2026-11-12, and all checks passed. The recommendations come from the code and from these checks.

| Label (Mac) | Recommendation | Reason |
|---|---|---|
| VoiceOver | Declare. | The code gives each control a name, a type and a value. Check 1 passed: the menu bar window, the row groups and the dialog work. |
| Voice Control | Declare. | Each action is a standard control with a name that includes the visible text. Check 2 passed. |
| Dark Interface | Declare. | The code has no fixed light color and no appearance override. Check 6 passed. |
| Differentiate Without Color Alone | Declare. | Each status has a text or a symbol with its color. Check 7 passed. |
| Sufficient Contrast | Declare. | Some colored text is below 4.5 to 1 in the light appearance by default. See "Known limits". Apple permits the label when Increase Contrast gives sufficient contrast in an app that uses the Apple frameworks. Check 4 passed. |
| Reduced Motion | Declare. | Each custom animation fades or stops with Reduce Motion. Check 5 passed. |
| Larger Text | Not available on Mac. | — |
| Captions | Not applicable. Do not select it. | Topway has no video and no audio. |
| Audio Descriptions | Not applicable. Do not select it. | Topway has no video. |

Do the evaluation again for each release that changes a screen.

## Common tasks and evidence

The columns are the six labels for Mac: VoiceOver (VO), Voice Control (VC), Dark Interface (DI), Differentiate Without Color Alone (DC), Sufficient Contrast (SC) and Reduced Motion (RM). Each cell gives the evidence items from the list below the table. An item with "check" needs the manual check of that number.

| Common task | VO | VC | DI | DC | SC | RM |
|---|---|---|---|---|---|---|
| Open Topway from the menu bar and read the health | E2, check 1 | E2, check 2 | E10 | E11a | E12 | E13e |
| Start screen, **Try with sample data**, **Exit sample data** | E1, E5 | E1 | E10 | E11b | E12a | E13a |
| Settings: token, Workspace ID, **Save** | E1, E7 | E1 | E10 | E11g | E12, check 4 | E13e |
| See the projects, open or close a project, **Refresh** | E1, E3, E4, E6 | E1, E3 | E10 | E11c | E12 | E13b |
| **Usage and cost**: cost, period, limits, **Refresh** | E1, E3, E4, E16 | E1 | E10 | E16 | E12 | E13a |
| Open a service, change the environment, change the tab | E1, E3, E4, E9 | E1, E3, check 2 | E10 | — | E12 | E13a |
| Variables: **Show**, **Copy**, **Copy all** | E3, E5, E7 | E3 | E10 | — | E12 | E13d |
| Variables: the targets of references and their status | E3 | — | E10 | E11i | E12 | — |
| Add, edit and delete a variable | E1, E4, E8, E9 | E1, E8 | E10 | E11f | E12, check 4 | E13a, E13c |
| Variable editor: **Insert reference**, **Suggestions** | E1, E3, E7 | E1, E3 | E10 | — | E12 | — |
| Service settings: name, commands, paths, **Save changes** | E1, E4, E7, E8, E9 | E1, E8 | E10 | E11g, E18 | E12, check 4 | E13a, E13c |
| Domains: list, DNS records, **Copy**, **Copy value**, **Add Railway domain**, **Add custom domain**, **Delete…** | E1, E3, E4, E7, E8, E9 | E1, E3, E8 | E10 | E11f, E18, E19 | E12, check 4 | E13a, E13c, E13d |
| Deployments: list, **View logs**, **Open URL**, **Restart**, **Redeploy** | E3, E5, E8 | E3, E8 | E10 | E11d | E12 | E13c |
| Deployment **Manage** menu: **Roll back…**, **Cancel deployment…**, **Remove deployment…** | E1, E3, E8 | E1, E3, E8 | E10 | E11f | E12, check 4 | E13c |
| Metrics: charts, **Time range**, **Refresh** | E1, E15 | E1 | E10 | E15 | E12 | E13f |
| Logs: tabs, follow, **Copy logs**, **Retry** | E1, E4, E6, E7 | E1, check 2 | E10 | E11e | E12b, check 4 | E13d |
| Add a service or a database | E1, E4, E6, E8 | E1, E8 | E10 | — | E12 | E13a, E13c |
| Delete a project or a service (type the name) | E8, check 1 | E8, check 2 | E10, E14, check 8 | E11f | E12c, check 4 | E13c |
| Service links: list, **Environment**, **Refresh** | E1, E3, E4, E9 | E1 | E10 | E11i | E12 | E13a |
| Environments: list, **New environment**, **Delete…** (type the name) | E1, E3, E4, E8, E9 | E1, E3, E8 | E10 | E11f, E18 | E12, check 4 | E13a, E13c |
| Mute alerts | E1, E3 | E1, E3 | E10 | E11c | E12 | — |
| Settings: auto refresh, alerts, launch at login, **Remove token…**, Help | E1 | E1 | E10 | E11f, E11g | E12, check 4 | E13e |
| Railway incident banner: **Open status page**, **Hide** | E1, E17 | E1, E17 | E10 | E17 | E12a | E13g |
| Error and empty states | E1, E7 | E1 | E10 | E11g | E12 | — |
| Notifications | System | System | System | E11h | System | System |
| **Quit Topway** | E1 | E1 | E10 | — | E12 | — |

### Evidence

**E1. Standard controls with text labels.** All actions are `Button`, `Menu`, `Picker`, `Toggle`, `TextField`, `SecureField`, `TextEditor` and `Link`. Settings is a `Form`. Empty states are `ContentUnavailableView`. The system gives these controls their type, their value and their keyboard use. Topway has no custom control and no custom text entry. No action shows only on hover: `RowButtonBody` uses hover only for a highlight. The only action with no control is a click on the dialog backdrop, and **Cancel** does the same.

**E2. Menu bar icon.** `MenuBarLabel` gives the icon the label "Topway", "Topway, build or deploy in progress" or "Topway, 2 services failing". The words come from `HealthSummary.statusDescription` in `TopwayCore`, with tests in `HealthSummaryTests`.

**E3. Rows.**
- `ProjectRow`: the label is the project name, the value is "Expanded" or "Collapsed", with "alerts muted" for a muted project. **Add service** has the label "Add service to" and the project name.
- `ServiceRow`: the label is the service name, not the names of its symbols.
- `ProjectMenu` and `ServiceMenu`: the label is "Manage" and the name of the item. The **Manage** menu of `DeploymentRow` has the label "Manage" and the status and date of the deployment.
- `EnvironmentRow`: the row is a group with the name of the environment. **Delete…** has the label "Delete" and the name of the environment.
- `DomainRow`: the row is a group with the domain name. **Copy** and **Delete…** name the domain. `DNSRecordRow` is a group with the label "CNAME record shop", and **Copy value** has the label "Copy value of CNAME record shop".
- `VariableRow` and `DeploymentRow`: the row is a group with the name of the item. Each button names its item, for example "Copy value of DATABASE_URL" and "Restart, Running, 11/10/26, 10:00".
- `ReferenceSuggestions`: a group with the label "Suggestions". Each button has the label "Insert reference to postgres.DATABASE_URL", and `accessibilityInputLabels` gives Voice Control the visible text. **Insert reference** is a standard `Menu` with a submenu for each service.
- `ServiceLinkSection`: a group with the name of the service, or "Shared variables". Each link is one item with a sentence that has names only, for example "worker uses billing in BILLING_URL. The project has no service with this name." (`ServiceGraph.sentence(for:)`, tested). The arrow symbols are not read.
- `ReferenceLinkRow`: one item for each target of a reference, with the label "Reference to postgres.DATABASE_URL: Found" (`ReferenceLink.accessibilityDescription`, tested). It has names only, never a value, so it does not show a hidden value.
- Where the label has more words than the visible text, `accessibilityInputLabels` gives Voice Control the visible text first: "Manage", "Add service", "Show", "Copy", "Edit", "View logs", "Open URL", "Restart", "Delete", "Copy value", and the name on the back button.

**E4. Headers and back.** The title of each screen and of the dialog has the header trait (`ProjectsHeader`, `ScreenHeader`, `GlassConfirmationDialog`). The back button has the label "Back to" and the name of the screen.

**E5. Symbols that only decorate.** The status dot of a deployment, the dialog backdrop and the progress symbol in the confirm button are hidden from assistive technologies. A hidden variable value reads as "Hidden value".

**E6. Status in words.** `LogLineRow` reads a line as "Warning:" or "Error:" and the message. `LogConnectionLabel` reads as "Connection: Live". Each progress indicator has a label, for example "Loading projects".

**E7. Announcements.** `ErrorBanner` and `ErrorStateView` post an `AccessibilityNotification.Announcement` when an error shows. `CopyButton` posts "Copied". Settings posts "Saved" or the save error. The service settings post "Saved". The variable editor posts "Suggestions are below the value." when reference suggestions show.

**E8. Confirmation dialog.** `destructiveConfirmation` disables the content behind the dialog and hides it from assistive technologies. The card has the modal trait. The keyboard focus goes to the name field. With no name field, the VoiceOver focus goes to the title. **Cancel** has the cancel shortcut (Escape). Return confirms only an action that is not destructive. The name field is a standard `TextField`, so Voice Control can dictate into it.

**E9. Keyboard.** `onExitCommand` in `MainView`, `ServiceView`, `AddServiceView`, `EnvironmentsView`, `NewEnvironmentView`, `NewDomainView` and `ServiceLinksView` goes back one step. Command-Return saves a variable or the service settings. Command-R refreshes the projects.

**E10. Dark Interface.** All colors are system colors (`.red`, `.orange`, `.green`), hierarchical styles (`.secondary`, `.tertiary`), the tint and system materials. The only fixed color is the black backdrop of the dialog at 30 % opacity, which is dark. No view sets `preferredColorScheme`. Settings is a system `Form`.

**E11. Differentiate Without Color Alone.**
- a. Menu bar health: three different symbols (tram, arrows, warning triangle).
- b. Sample data: the text "Sample data" and a symbol, with the orange tint.
- c. Muted project: a bell with a line. Open or closed project: the direction of the chevron.
- d. Deployment status: the status text is next to the colored dot.
- e. Logs: a warning has a triangle, an error has an octagon. The connection has a different symbol and a text for each state.
- f. Destructive actions: the red text has the word "Delete" or "Remove". The production label has the text "Production environment" and an octagon.
- g. Errors and results: a symbol and a text ("Saved", the error message).
- h. Notifications: the title says the result, for example "Deployment failed".
- i. Reference status: each status has a text and a different symbol: "Found" (check mark), "Service not found" and "Variable not found" (triangle), "Set by Railway" (circle with "i") and "Not checked" (question mark). Only the triangle is orange. The text is in the primary color. In **Service links**, a missing service shows the text "Service not found" with the triangle, and the direction of a link is in the words **Uses** and **Used by**, not only in the arrow.

**E12. Sufficient Contrast.** Text uses the system text styles and the system colors, which change with Increase Contrast. Primary text is the default for names, values and log lines of the info level.
- a. `SampleDataBanner`: the text is in the primary color. Only the symbol is orange.
- b. `LogLineRow`: warning lines are orange and error lines are red. See "Known limits".
- c. `GlassConfirmationDialog`: the production label is red text with a symbol, not white text on red.

**E13. Reduced Motion.** Topway has one custom animation, `Animation.screenChange` (0.2 seconds).
- a. Screen change (`MainView`, `ServiceView`): with Reduce Motion, `AnyTransition.screen(reduceMotion:)` only fades.
- b. A project that opens or closes (`ProjectRow`): with Reduce Motion, no animation.
- c. The dialog (`destructiveConfirmation`): with Reduce Motion, it only fades and does not change size.
- d. Logs and copy: the scroll to the newest line has no animation. The "Copied" text changes with no animation.
- e. System motion: the menu bar window, the Settings window, the progress indicators and the glass buttons are system components. The system controls their motion.
- f. Charts: `MetricCard` has no animation. New samples replace the old samples with no motion.
- g. Incident banner: `IncidentBanner` shows and hides with no animation.

Topway has no parallax, no symbol effect, no animation that repeats and no content that moves by itself, apart from new log lines. The user stops that with a scroll up.

**E14. Reduce Transparency.** With Reduce Transparency, the dialog card is opaque (`GlassConfirmationDialog`). All other glass comes from the system button styles.

**E15. Charts.** `MetricCard` shows the name, the latest value and the highest value of a metric as text, and VoiceOver reads them as one item. The chart is hidden from assistive technologies, because it only shows the trend of the same values. A chart has one series, so no value depends on a color.

**E16. Usage.** `SpendRow` has the label "Usage and cost". `SpendSummary` reads the cost, its period and the days left as one item. The progress bar of the limit has the limit amounts as its label and "50 percent of the limit" as its value. A cost above the limit shows as red text with an octagon and the words "The usage is above the limit."

**E17. Incident banner.** `IncidentBanner` is a group with the label "Railway incident". It shows the status and the title of the incident as text, with a warning triangle and the orange tint, and the text is in the primary color. It posts an `AccessibilityNotification.Announcement` one time for each incident, because it shows with no user action. It does not say the same incident again when the window opens again. **Hide** has the label "Hide incident", and `accessibilityInputLabels` gives Voice Control the visible text first.

**E18. Form messages.** A problem with a typed value shows as text below its field, with a warning triangle, for example "This project has an environment with this name. Use a different name." The button of the form is then not available. The symbol is orange, and the text is in the primary color.

**E19. Domain status.** A custom domain shows its status as text with a symbol: "Set the DNS records" (triangle), "Railway makes the certificate" (clock), "Certificate failed" (octagon with a cross, and a text that says what to check) or "Ready" (check mark). A DNS record shows "Set" (check mark) or "Not set" (clock). No status uses a color.

### Known limits

- **Colored text in the light appearance.** By default, orange text (log warnings) is near 2.2 to 1 on a white background, and red text (log errors, destructive buttons, error messages) is near 3.6 to 1. The design keeps red text on destructive buttons. The system colors get darker with Increase Contrast. Check 4 must show that they are then sufficient.
- **White text on the red confirm button.** The system draws the prominent button of a destructive dialog. Check 4 must show its contrast in the two appearances.
- **Secondary text.** Dates, counts, hints and the **Add service** row use `.secondary`. The system makes it stronger with Increase Contrast.
- **Menu bar name for Voice Control.** The icon has no visible text, and its name changes with the health. "Click Topway" can fail when the health is not healthy. "Show numbers" always works.
- **No main menu.** Topway has no Dock icon and no visible main menu (`LSUIElement`). All actions are in the menu bar window and in Settings.

## Manual checks

Do each check in sample mode (**Try with sample data**) and go through all rows of the table above. Sample mode ends when you save a token, so do the credential tasks (enter the token and the Workspace ID, **Save**, **Remove token…**, and the rejected token screen) again with a real token. A check passes when you can complete each task with only that feature.

1. **VoiceOver.** Press Command-F5. Press VO-M two times to go to the status menus, find Topway and press VO-Space. Move with VO-Right and VO-Left. Go into a row group with VO-Shift-Down.
   - VoiceOver says the name, the type and the value of each control.
   - The VoiceOver cursor goes into the window when it opens, and into the dialog when it shows.
   - In a dialog, you cannot get to the content behind it. Escape cancels.
   - VoiceOver says an error when an action fails. To make an error, turn off the network with a real token.
   - Do the same in the Settings window.
2. **Voice Control.** Turn it on in **System Settings > Accessibility > Voice Control**. Say "Show names", then "Show numbers".
   - Each button, menu, tab and field has a name and a number.
   - "Click Manage", "Click Restart", "Click Variables" and "Click Projects" work.
   - In the delete dialog, dictate the name into the field. The name must be exact.
   - "Scroll down" works in the lists and in the logs.
3. **Full keyboard.** Use only Tab, Space, Return, the arrow keys and Escape for each task.
4. **Increase Contrast.** Turn on **System Settings > Accessibility > Display > Increase contrast**. Do the check in the light appearance and in the dark appearance. Then do it again with Reduce transparency on.
   - You can read all text, also orange text, red text and secondary text.
   - You can read the label of the red confirm button.
   - Use the Accessibility Inspector of Xcode to measure text that you are not sure about. The minimum is 4.5 to 1.
5. **Reduce Motion.** Turn on **Display > Reduce motion**. Open a service, open the logs, go back, open a dialog, open and close a project.
   - Screens and the dialog fade. No content moves across the window or changes size.
6. **Dark and Light.** Change **System Settings > Appearance**. Look at each screen, the dialog and Settings in the two appearances.
   - No screen shows a large light area in the dark appearance.
7. **Color.** Turn on **Display > Color filters > Grayscale**.
   - You can tell each status, each log level and each destructive action without color.
8. **Reduce Transparency.** Turn on **Display > Reduce transparency**. Open a dialog.
   - The dialog card is opaque, and you can read the bars above the lists.

Record the date, the macOS version and the result of each check in the pull request or the release notes.

## Rules for new screens

[DESIGN.md](../DESIGN.md) has the rules. The short list:

- Give each control a text label. If the accessibility label has more words than the visible text, add `accessibilityInputLabels` with the visible text first.
- A button that shows in each row must name its item in the accessibility label.
- Do not show a status by color only.
- Read `accessibilityReduceMotion` for each custom animation and transition.
- Post an announcement for a result that shows away from the control, such as an error.

## Sources

- [VoiceOver evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voiceover-evaluation-criteria)
- [Voice Control evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voice-control-evaluation-criteria)
- [Dark Interface evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/dark-interface-evaluation-criteria)
- [Differentiate Without Color Alone evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/differentiate-without-color-alone-evaluation-criteria)
- [Sufficient Contrast evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/sufficient-contrast-evaluation-criteria)
- [Reduced Motion evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)
