# Topway

Topway puts your Railway projects in the macOS menu bar. You can check your services, read live logs and restart or roll back a deployment, with no browser tab open.

## What you can do

- **Projects and services**: See all projects and their services. Add a service from a GitHub repository or a Docker image, or add a PostgreSQL, MySQL, Redis or MongoDB database. Railway bills the usage of a database.
- **Environments, settings and domains**: Create, copy and delete environments. Change the build command, start command, root directory and healthcheck path. Add a Railway domain or a custom domain, and see the DNS records that you must set.
- **Variables**: Show, copy and edit variables. Topway checks each reference, such as `${{ postgres.DATABASE_URL }}`, and helps you insert new ones. **Copy all** gives you the variables in `.env` format.
- **Deployments and logs**: Restart, redeploy, roll back, cancel or remove a deployment. Read the build and deploy logs live.
- **Metrics and cost**: See CPU, memory and network charts for the last hour, 6 hours or 24 hours. See the cost of the current billing period, as Railway reports it. It is not your invoice.
- **Health and alerts**: The menu bar icon shows the health of all services. Turn on alerts to get a notification when a deployment fails, a service crashes or a service recovers. You can mute a project.
- **Service links**: See which services use the variables of other services.
- **Railway incidents**: A banner tells you when Railway reports an open incident.

Each action has a text label. No action hides until you hover over a row. To delete a project, a service or an environment, you type its name.

## Paid on the App Store, free to build

Topway will be a paid app on the Mac App Store (coming soon). It is also open source under the [MIT license](LICENSE). You can build it from source, fork it and own it, at no cost.

If you buy Topway on the App Store, you support the developer. Buying it is optional.

## Get started

1. Get Topway from the Mac App Store (coming soon), or [build it from source](#build-from-source).
2. Open Topway. Its icon is in the menu bar, not in the Dock. At the first launch, a welcome window shows what Topway does and where its icon is.
3. Select **Sign in with Railway**. Sign in on the Railway page that opens, then select the workspaces that Topway can use.
4. If you selected more than one workspace, choose one. To change it later, go to **Settings > Account > Workspace**.

Topway keeps your sign-in in the Keychain and renews it for you.

### Try it with sample data

You can use Topway with no Railway account. On the start screen, select **Try with sample data**.

- Topway shows sample projects, services, deployments, variables, metrics, usage and logs. Each screen shows the label **Sample data**.
- Topway does not connect to Railway, and it does not use or save a sign-in.
- You can restart, redeploy, edit and delete. Your changes stay in memory until you exit sample data or quit Topway.
- To go back to the start screen, select **Exit sample data**. A sign-in also ends sample data.

### If Railway does not accept your sign-in

Railway can end a sign-in, for example when you remove the access of Topway, or after one year with no use. Topway then shows the start screen, and you sign in again.

When your sign-in has no access to a workspace or an action, Topway shows **Railway did not accept your sign-in**. Select **Sign in again** and select the workspace on the Railway consent page, or select **Try with sample data**.

### Sign out

Select **Settings > Account > Sign out…** to remove the sign-in from your Mac. Railway does not let an app revoke its own access. To remove the access of Topway, open your Railway account settings and select **Apps**.

## Limitations

- Topway cannot create a project, because the Railway public API does not support it. **New project** opens Railway in your browser.
- New services come from a GitHub repository, a Docker image or one of the four database templates. Other templates are not available.
- You connect only with Sign in with Railway. Topway has no field for an API token.

## Build from source

You need Xcode 26.2 or later on macOS 26.2 or later. Open `topway.xcodeproj` and run the `topway` scheme.

A build with no OAuth client ID works, but it offers only sample data. To sign in from your own build, make your own Railway OAuth app:

1. In Railway, open the settings of your workspace, then **Developer > New OAuth App**. Only a workspace admin can do this.
2. For the type, select **Native (Public)**. A native app has no client secret, and Topway sends none.
3. Add the redirect URI `https://topway.pulgueta.com/oauth/callback`. It must match exactly.
4. Copy the client ID.
5. Make the file `Config/OAuth.local.xcconfig` with this line:

   ```text
   RAILWAY_OAUTH_CLIENT_ID = your_client_id
   ```

6. Build the app again.

Git ignores `Config/OAuth.local.xcconfig`. Never commit it, and never put the client ID in `Config/OAuth.xcconfig`.

### Sign in from a build that another team signs

The sign-in callback uses Associated Domains on `topway.pulgueta.com`. That domain gives the callback only to an app that the Topway team (7QNFW3929Z) signs, so a build that a different team signs cannot complete the sign-in.

For such a build, use a domain of your own. Put an `apple-app-site-association` file with your team ID and bundle ID on it. Then use that domain in `RailwayOAuth.callbackHost`, in `topway/topway.entitlements` and in the redirect URI.

To change the code, read [CONTRIBUTING.md](CONTRIBUTING.md).

## Accessibility

Topway works with VoiceOver, Voice Control, the keyboard, the dark appearance, Increase Contrast, Reduce Motion and Reduce Transparency. A color is never the only sign of a status. [docs/accessibility.md](docs/accessibility.md) has the details.

## Report a problem

Topway collects no data and sends no crash reports, so your reports help.

In Topway, select **Settings > Help**, then **Report a problem** or **Report a crash**. Topway opens a GitHub issue form in your browser, with the Topway version, the macOS version, the Mac model, the architecture and the data mode filled in. Nothing goes to GitHub until you send the form.

You can also [open a new issue](https://github.com/pulgueta/topway/issues/new/choose) and select **Crash report**, **Bug report** or **Feature request**.

Issues are public. Do not paste a Railway token, your Workspace ID or the values of your variables, and remove them from logs and screenshots. For a security problem, [send a private report](https://github.com/pulgueta/topway/security/advisories/new).

## Privacy

Topway collects no data. It keeps your sign-in in the Keychain and connects only to Railway. Read the [privacy policy](PRIVACY.md).
