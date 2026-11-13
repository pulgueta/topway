# Topway

Topway is a native macOS menu bar application for monitoring and managing your Railway projects and services. Built with SwiftUI, it lives in your menu bar to provide quick access to your infrastructure without needing to keep the Railway dashboard open in a browser tab.

## Features

Each action in Topway has a text label. No action shows only when the pointer is on a row. [DESIGN.md](DESIGN.md) gives the design rules.

### Projects and Services
- The first screen shows all your Railway projects and their services.
- **Refresh** and **Settings** are at the top. **New project** opens Railway in your browser. **Quit Topway** is at the bottom.
- **Add service**: Select **Add service** below the services of a project. You can add a service from a GitHub repository or a Docker image, or add a database.
- **Database**: In **Add service**, select **Database**, then PostgreSQL, MySQL, Redis or MongoDB, and the environment. Railway adds the database from its template, with a volume and the connection variables, and starts it. Railway bills its usage. While Railway makes the database, the screen shows **Railway adds the database…**. **Close** goes back to the projects, and Railway continues. If Topway does not see the result in 60 seconds, select **Refresh** later to see the database. Do not add it again.
- **Manage**: Each project has a **Manage** menu, with **Add service**, **Environments**, **Mute alerts** and **Delete project…**.
- Select a service to see its variables, deployments and metrics. The **Manage** menu of the service has **Settings**, **Domains**, **Redeploy** and **Delete service…**.
- To delete a project or a service, you must type its name.

### Service links
- In the **Manage** menu of a project, select **Service links**. For each service, the screen shows the services that it uses (**Uses**) and the services that use it (**Used by**), with the names of the variables that have the references. The shared variables show when a service uses them.
- A reference to a service that the project does not have shows **Service not found**.
- The screen shows one environment. If the project has more than one environment, select the environment at the top. **Refresh** loads the links again. The screen does not change a variable.

### Environments
- In the **Manage** menu of a project, select **Environments**. The screen shows the environments of the project.
- **New environment**: Enter a name. The environment is empty, or a copy of an environment that you select in **Copy from**. A copy gets the services, the variables and the settings, and its services deploy.
- **Delete…**: To delete an environment, you must type its name. Railway removes the deployments, the variables and the data of all services in that environment.

### Service settings
- In the **Manage** menu of a service, select **Settings**. The screen shows the name of the service, its source, and these settings of the selected environment: build command, start command, root directory and healthcheck path.
- **Save changes** sends only the settings that you changed. A new name applies to all environments. The other settings apply to the next deployment in the selected environment.
- Railway uses its default for an empty field. Topway does not change the source of a service.

### Domains
- In the **Manage** menu of a service, select **Domains**. The screen shows the Railway domain and the custom domains of the service in the selected environment.
- **Add Railway domain**: Railway makes a public address on `up.railway.app`. A service gets one Railway domain in an environment.
- **Add custom domain**: Enter a domain that you own, for example `app.example.com`. The list then shows the DNS records that you must set at your DNS provider, with **Copy value** for each record. Each record shows **Set** or **Not set**.
- A custom domain shows its status: **Set the DNS records**, **Railway makes the certificate**, **Certificate failed** or **Ready**. **Certificate failed** shows what to check.
- **Copy** copies the domain name. **Delete…** removes the domain from the service.

### Environment Variables
- The **Variables** tab of a service shows its variables in one environment.
- **Environment**: If the project has more than one environment, select the environment at the top.
- **Show**, **Copy** and **Edit**: Each variable has these buttons. Values are hidden until you select **Show**.
- **References**: A value can use the variable of a different service (`${{ postgres.DATABASE_URL }}`), a shared variable (`${{ shared.LOG_LEVEL }}`) or a variable of the same service (`${{ PORT }}`). Below the value, the row shows each target and its status: **Found**, **Service not found**, **Variable not found**, **Set by Railway** (a `RAILWAY_` variable, which Topway cannot check) or **Not checked** (the other variables did not load). **Show**, **Copy** and **Copy all** give the reference, not the value that Railway makes from it.
- **Copy all** copies all variables as `NAME=value` lines. A value with a line break or a double quotation mark is put in double quotation marks, as in a `.env` file.
- **Add variable** is at the bottom. To delete a variable, select **Edit**, then **Delete variable…**.
- **Insert reference**: In the editor, select a service (or **This service** or **Shared variables**), then a variable. Topway puts `${{service.VARIABLE}}` at the cursor. You can also type `${{` in the value: **Suggestions** shows the variables that match the text after it. Select one to complete the reference.

### Deployments
- The **Deployments** tab of a service shows its latest deployments and their status, for example Running, Failed or Building.
- **View logs**, **Open URL** and **Restart**: Each deployment has these buttons. **Open URL** shows only when the deployment has a URL.
- **Redeploy** builds and starts a new deployment of the service.
- **Manage**: A deployment has this menu when it permits one of these actions. **Cancel deployment…** stops a build or a deploy that is in progress. **Roll back…** deploys an earlier deployment again, when Railway permits it. **Remove deployment…** stops the service in the environment. Each action asks for a confirmation.

### Railway incidents
- When Railway reports an open incident, a banner **Railway incident** shows at the top of each screen, with the status and the title of the incident.
- **Open status page** opens the Railway status page in your browser. **Hide** hides the banner until Railway reports a different incident.
- Topway asks Railway for the platform status at most one time in 5 minutes, when it loads the projects or when you open the window. This request has no token.

### Usage and cost
- On the projects screen, select **Usage and cost**. The screen shows the cost of the usage in the current billing period of the workspace, the dates of the period and the days that are left.
- Railway gives the cost. Topway calculates no price. The cost can be some minutes old, and it is not your invoice.
- The screen shows the email alert and the hard limit of the workspace, when they are set.
- The screen shows the use of CPU, memory, network egress and volumes in the period.

### Metrics
- The **Metrics** tab of a service shows CPU, memory, network in and network out in one environment.
- Each metric shows its latest value, its highest value and a chart.
- **Time range**: Select **Last hour**, **Last 6 hours** or **Last 24 hours**. **Refresh** loads the metrics again.

### Logs
- **Live logs**: On a deployment row, select **View logs**. The logs screen has the tabs **Build** and **Deploy**. It opens on **Build** when the deployment builds, waits to deploy or failed.
- **Levels**: Warnings show in orange with a triangle. Errors show in red with an octagon.
- **Follow**: The screen moves to new lines. If you scroll up, it stops. Select **Follow new lines** to go to the newest line again.
- **Copy logs**: Copies the lines on the screen, with their timestamps. The screen keeps the newest 1,000 lines.
- **Connection**: The footer shows **Live**, **Reconnecting...** or **Checks every 5 seconds**. When a log has no more lines, it shows **End of log**. When an error stops the log, it shows **Stopped** and the error. Select **Retry** to start the log again. Topway uses a live connection to Railway. If it cannot connect, it reads the logs every 5 seconds.
- Log text stays on your Mac. Topway does not send it to other services.

### Health and Alerts
- **Menu bar health**: The menu bar icon shows the health of all services. The tram shows when all services are healthy. Arrows show when a build or a deploy is in progress. A warning triangle shows when a service failed or crashed.
- **Background refresh**: When auto-refresh is on, Topway refreshes from launch, also when the menu bar window is closed. Turn it on in **Settings > Auto Refresh**. Topway checks for alerts at each refresh.
- **Alerts**: Turn on **Settings > Alerts > Send alerts** to get a notification when a deployment fails, a service crashes or a service recovers. Alerts are off by default. Topway asks for notification permission when you turn them on. If you denied the permission, select **Open System Settings**.
- **Mute**: When alerts are on, select **Manage** in a project row, then **Mute alerts**. A muted project shows a bell with a line.
- **Launch at login**: Turn on **Settings > General > Launch at login**. If macOS asks for approval, select **Open Login Items**.

## Limitations

- **Project Creation**: Creating new projects is not currently supported via the Public API endpoints available to this application. The app provides a shortcut to the Railway Dashboard for this action.
- **Service Creation**: You can create services from **GitHub repositories**, **Docker images** and the four **database** templates (PostgreSQL, MySQL, Redis, MongoDB). Other templates are not available in Topway.
- **Authentication**: Topway connects only through Sign in with Railway. It has no field for an API token. Sample mode needs no account.
- **Sign out**: Railway has no way for an app to revoke its own access. **Sign out…** removes the sign-in from your Mac. To remove the access of Topway on Railway, open your Railway account settings and select **Apps**.

## Getting Started

1. Download or build the app.
2. Open Topway. It shows in the menu bar, not in the Dock. At the first launch, the **Welcome to Topway** window tells what Topway does and shows the icon to look for. Select **Continue** to see the next page, and **Done** or **Skip** to close the window. The window does not show again.
3. Select **Sign in with Railway**. A browser window opens the Railway sign-in page.
4. Sign in to Railway. On the consent page, select the workspaces that Topway can use, then accept.
5. If you selected more than one workspace, select the workspace in the list. To change it later, select **Settings > Account > Workspace**.

Topway keeps the sign-in in the Keychain of your Mac and renews it automatically. If you used an API token with an earlier build, Topway removes that token at launch, and you sign in one time.

### If Railway does not accept the sign-in

Railway can end a sign-in, for example when you remove the access of Topway on Railway, or when you do not use Topway for one year. Topway then shows the start screen and tells you to sign in again.

When the sign-in has no access to a workspace or an action, Topway shows **Railway did not accept your sign-in**, with two buttons:

- **Sign in again**: Sign in, and select the workspace on the Railway consent page.
- **Try with sample data**: Use Topway with no account.

To remove the sign-in from your Mac, select **Settings > Account > Sign out…**. Topway then shows the start screen.

## Sample Data

You can use Topway with no Railway account. On the start screen, select **Try with sample data**. The same button shows when Railway does not accept your sign-in.

- Topway shows sample projects, services, deployments, variables, metrics, usage and logs. The label **Sample data** shows at the top of each screen.
- Topway does not connect to Railway. It does not use or save a sign-in.
- You can restart, redeploy, edit variables and delete items. The changes stay in memory until you exit sample mode or quit the app.
- Sample mode shows a sample incident banner. Its text starts with "Sample incident".
- Sample mode can send alerts. Each sample notification shows **Sample data**.
- To go back to the start screen, select **Exit sample data**. If you sign in, Topway also exits sample mode.

## Build from Source

You need Xcode 26.2 or later. Open `topway.xcodeproj` and run the `topway` scheme. A build with no OAuth client ID works, but it offers only sample data.

To sign in from your own build, make your own Railway OAuth app:

1. In Railway, open the settings of your workspace, then **Developer > New OAuth App**. Only a workspace admin can do this.
2. For the type, select **Native (Public)**. A native app has no client secret, and Topway sends none.
3. Add the redirect URI `https://topway.pulgueta.com/oauth/callback`. The text must be the same.
4. Copy the client ID.
5. Make the file `Config/OAuth.local.xcconfig` with this line:

   ```
   RAILWAY_OAUTH_CLIENT_ID = <your client ID>
   ```

6. Build the app again.

Git ignores `Config/OAuth.local.xcconfig`. Never commit it, and never put the client ID in `Config/OAuth.xcconfig`.

The callback uses Associated Domains on `topway.pulgueta.com`, and that domain gives the callback only to an app that the Topway team (7QNFW3929Z) signs. A build with a different team cannot complete the sign-in. For such a build, use a domain of your own: put an `apple-app-site-association` file with your team ID and bundle ID on it, then use that domain in `RailwayOAuth.callbackHost`, `topway/topway.entitlements` and the redirect URI.

## Accessibility

Topway is made to work with VoiceOver, Voice Control, the keyboard, the dark appearance, Increase Contrast, Reduce Motion and Reduce Transparency. A color is never the only sign of a status. [docs/accessibility.md](docs/accessibility.md) gives the details, the evaluation for the App Store labels and the manual checks.

## Report a Problem

Topway collects no data and sends no crash reports. To tell us about a problem, open an issue on GitHub.

The fastest way is from the app. Select **Settings > Help**, then **Report a problem** or **Report a crash**. Topway opens the form on GitHub in your browser and fills in the Topway version, the macOS version, the Mac model, the architecture and the data mode. Topway sends nothing by itself. You read the form, add your text and send it.

You can also [open a new issue](https://github.com/pulgueta/topway/issues/new/choose) and select a form:

- **Crash report**: Topway quit when you did not tell it to quit. The form tells you how to find the macOS crash report.
- **Bug report**: Topway did something wrong, but it did not quit.
- **Feature request**: You have an idea for a change.

Issues are public. Do not paste a Railway token, your Workspace ID or the values of your variables. Remove them from logs and screenshots.

For a security problem, [send a private report](https://github.com/pulgueta/topway/security/advisories/new).

## Privacy

Topway collects no data. It keeps your sign-in in the Keychain and connects only to Railway. Read the [privacy policy](PRIVACY.md).
