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

- Topway shows sample projects, services, deployments and variables. The label **Sample data** shows at the top of each screen.
- Topway does not connect to Railway. It does not read or save your token.
- You can restart, redeploy, edit variables and delete items. The changes stay in memory until you exit sample mode or quit the app.
- To go back to the start screen, select **Exit sample data**. If you save a token in Settings, Topway also exits sample mode.
