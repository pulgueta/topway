# Privacy Policy

Last update: 2026-11-12

Topway is a macOS menu bar app for Railway. Topway collects no data.

## What Topway does not do

- Topway does not collect, sell or share your data.
- Topway has no analytics, no advertisements and no tracking.
- Topway sends no crash reports and no usage data.
- Topway has no third-party code.
- The developer has no server. The developer cannot see your token, your projects or your variables.

## What Topway keeps on your Mac

| Data | Location | How to remove it |
|---|---|---|
| Railway API token | The Keychain of your Mac | Select **Settings > Credentials > Remove token…**. |
| Workspace ID | The app settings (`UserDefaults`) | Delete the app and its data. |
| Your settings: auto-refresh, alerts and muted projects | The app settings (`UserDefaults`) | Delete the app and its data. |

Projects, services, variables, deployments and logs stay in memory. Topway does not write them to disk.

## Where Topway sends data

Topway connects only to the Railway API (`backboard.railway.com`), through HTTPS and secure WebSockets.

- Topway sends your token to Railway to identify you.
- Topway sends your actions to Railway, for example a restart or a new variable value.
- Topway asks Railway for the platform status, to show a banner when Railway reports an incident. This request goes to the same address (`backboard.railway.com`), at most one time in 5 minutes. It contains no token and no data about you, your workspace or your projects.
- When you add a database, Topway asks Railway for the public template of that database. This request goes to the same address. It contains the template name, for example `postgres`, and no token.
- The button **Open status page** in the banner opens the Railway status page (`status.railway.com`) in your browser. Topway itself sends nothing to that page.
- The [Railway privacy policy](https://railway.com/legal/privacy) applies to the data that Railway keeps.

In sample mode, Topway does not connect to Railway and does not read or save a token. The incident banner then shows a sample incident.

## Notifications

If you turn on alerts, Topway shows notifications on your Mac. Topway makes them on your Mac. They do not go through a server.

## Problem reports

**Settings > Help** has the buttons **Report a problem** and **Report a crash**. Each button opens an issue form on GitHub in your browser. The link contains only these details: the Topway version, the macOS version, the Mac model, the architecture, and whether you use a Railway token or sample data.

- Topway sends nothing by itself. GitHub gets the report only when you send the form.
- You decide what the report contains. You can change or remove each detail first.
- Issues on GitHub are public. Do not include your token, your Workspace ID or the values of your variables.
- The [GitHub privacy statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement) applies to the data that you send to GitHub.

## Changes

If this policy changes, the new text is in this file. The file history on GitHub shows each change.

## Contact

For a question about privacy, [open an issue](https://github.com/pulgueta/topway/issues/new/choose). For a security problem, [send a private report](https://github.com/pulgueta/topway/security/advisories/new).
