# Privacy policy

Last update: 2026-11-13

Topway is a macOS menu bar app for Railway. **Topway collects no data.**

## What Topway does not do

- Topway does not collect, sell or share your data.
- Topway has no analytics, no advertisements, no tracking and no third-party code.
- Topway sends no crash reports and no usage data.
- The developer has no server, so the developer cannot see your sign-in, your projects or your variables.

## What Topway keeps on your Mac

| Data | Location | How to remove it |
|---|---|---|
| Railway sign-in: an access token and a refresh token | The Keychain of your Mac | **Settings > Account > Sign out…** |
| The ID of the selected workspace | The app settings (`UserDefaults`) | **Settings > Account > Sign out…** |
| Your settings: auto-refresh, alerts and muted projects | The app settings (`UserDefaults`) | Delete the app and its data. |
| A record that the welcome window showed one time | The app settings (`UserDefaults`) | Delete the app and its data. |

Your name, your email, the names of your workspaces, and your projects, services, variables, deployments and logs stay in memory. Topway does not write them to disk.

An earlier build of Topway kept a Railway API token in the Keychain. Topway removes that token at launch and does not use it.

## Where Topway sends data

Topway connects only to the Railway API (`backboard.railway.com`), through HTTPS and secure WebSockets.

### Sign in with Railway

- Topway opens the Railway sign-in page (`backboard.railway.com/oauth/auth`) in a system browser window. You sign in on that page, so Topway never gets your password.
- The window shares the cookies of your default browser, so Railway can see that you are signed in already. Topway cannot read these cookies.
- When you accept on the consent page, Topway sends the code from Railway, its client ID and a one-time verifier to `backboard.railway.com/oauth/token`. Railway sends back an access token and a refresh token. Topway has no client secret and sends none.
- Topway asks Railway for your name, your email and the workspaces that you shared with Topway. It shows them in **Settings > Account** and uses them to select the workspace.
- Each request to Railway contains the access token, which identifies you. The access token expires after one hour. Before that, Topway sends the refresh token to `backboard.railway.com/oauth/token` to get a new access token.
- **Sign out…** removes the tokens from your Mac. Railway has no way for an app to revoke its own access. To remove the access of Topway, open your Railway account settings and select **Apps**.

### Your actions and the status of Railway

- Topway sends your actions to Railway, for example a restart or a new variable value.
- To show a banner when Railway reports an incident, Topway asks `backboard.railway.com` for the platform status, at most one time in 5 minutes. This request contains no token and no data about you, your workspace or your projects.
- When you add a database, Topway asks the same address for the public template of that database. The request contains the template name, for example `postgres`, and no token.
- **Open status page** in the banner opens the Railway status page (`status.railway.com`) in your browser. Topway itself sends nothing to that page.

The [Railway privacy policy](https://railway.com/legal/privacy) applies to the data that Railway keeps.

In sample mode, Topway does not connect to Railway, and it does not use or save a sign-in. The incident banner then shows a sample incident.

## Notifications

If you turn on alerts, Topway makes the notifications on your Mac. They do not go through a server.

## Problem reports

In **Settings > Help**, **Report a problem** and **Report a crash** open an issue form on GitHub in your browser. The link contains only the Topway version, the macOS version, the Mac model, the architecture, and whether you are signed in to Railway or use sample data.

- Topway sends nothing by itself. GitHub gets the report only when you send the form, and you can change or remove each detail first.
- Issues on GitHub are public. Do not include a token, your Workspace ID or the values of your variables.
- The [GitHub privacy statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement) applies to the data that you send to GitHub.

## Changes

If this policy changes, the new text is in this file. The file history on GitHub shows each change.

## Contact

For a question about privacy, [open an issue](https://github.com/pulgueta/topway/issues/new/choose). For a security problem, [send a private report](https://github.com/pulgueta/topway/security/advisories/new).
