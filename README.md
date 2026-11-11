# Topway

Topway is a native macOS menu bar application for monitoring and managing your Railway projects and services. Built with SwiftUI, it lives in your menu bar to provide quick access to your infrastructure without needing to keep the Railway dashboard open in a browser tab.

## Features

### Project & Service Monitoring
- View all your Railway projects in a clean, compact list.
- See services associated with each project.
- **Add Services**: Create new services from a GitHub repository or a Docker image.
- **Delete Projects/Services**: Manage your resources (with confirmation).

### Environment Variables
- **View & Edit**: easy access to environment variables for any service.
- **Multi-Environment Support**: Switch between environments (e.g., Production, Staging) to see scoped variables.
- **Clipboard Actions**: One-click copy for individual values or all variables at once.
- **Privacy**: Values are masked by default, toggle to reveal.

### Deployment Management
- **Status at a Glance**: View the latest deployments and their status (Success, Failed, Building, etc.).
- **Actions**:
  - Restart a specific deployment.
  - Trigger a full redeploy of a service.
  - Open the live deployment URL in your browser.

### Logs
- **Live logs**: On a deployment row, select **View logs**. The logs screen has the tabs **Build** and **Deploy**. It opens on **Build** when the deployment builds, waits to deploy or failed.
- **Levels**: Warnings show in orange with a triangle. Errors show in red with an octagon.
- **Follow**: The screen moves to new lines. If you scroll up, it stops. Select **Follow new lines** to go to the newest line again.
- **Copy logs**: Copies the lines on the screen, with their timestamps. The screen keeps the newest 1,000 lines.
- **Connection**: The footer shows **Live**, **Reconnecting...** or **Checks every 5 seconds**. Topway uses a live connection to Railway. If it cannot connect, it reads the logs every 5 seconds.
- Log text stays on your Mac. Topway does not send it to other services.

### Health and Alerts
- **Menu bar health**: The menu bar icon shows the health of all services. The tram shows when all services are healthy. Arrows show when a build or a deploy is in progress. A warning triangle shows when a service failed or crashed.
- **Background refresh**: When auto-refresh is on, Topway refreshes from launch, also when the menu bar window is closed. Turn it on in **Settings > Auto Refresh**. Topway checks for alerts at each refresh.
- **Alerts**: Turn on **Settings > Alerts > Send alerts** to get a notification when a deployment fails, a service crashes or a service recovers. Alerts are off by default. Topway asks for notification permission when you turn them on. If you denied the permission, select **Open System Settings**.
- **Mute**: When alerts are on, each project row has a bell. Select it to mute the alerts of that project.
- **Launch at login**: Turn on **Settings > General > Launch at login**. If macOS asks for approval, select **Open Login Items**.

## Limitations

- **Project Creation**: Creating new projects is not currently supported via the Public API endpoints available to this application. The app provides a shortcut to the Railway Dashboard for this action.
- **Service Creation**: You can create services from **GitHub repositories** and **Docker images**. Other sources (like databases) are not implemented.
- **Authentication**: Requires a valid Railway API Token and Workspace ID to function. Sample mode needs no token.

## Getting Started

1. Download/Build the app.
2. Launch Topway (it will appear in your menu bar).
3. Open **Settings**.
4. Enter your **Railway API Token** and **Workspace ID**.
   - *Token*: Generate this in your Railway Account Settings.
   - *Workspace ID*: Press `Cmd + K` in the Railway Dashboard and search for "Copy Active Workspace ID".

## Sample Data

You can use Topway with no Railway token. On the start screen, select **Try with sample data**.

- Topway shows sample projects, services, deployments, variables and logs. The label **Sample data** shows at the top of each screen.
- Topway does not connect to Railway. It does not read or save your token.
- You can restart, redeploy, edit variables and delete items. The changes stay in memory until you exit sample mode or quit the app.
- Sample mode can send alerts. Each sample notification shows **Sample data**.
- To go back to the start screen, select **Exit sample data**. If you save a token in Settings, Topway also exits sample mode.
