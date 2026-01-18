# Topway

Topway is a native macOS menu bar application for monitoring and managing your Railway projects and services. Built with SwiftUI, it lives in your menu bar to provide quick access to your infrastructure without needing to keep the Railway dashboard open in a browser tab.

## Features

### Project & Service Monitoring
- View all your Railway projects in a clean, compact list.
- See services associated with each project.
- **Add Services**: Create new services directly from a GitHub repository.
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
- **Service Creation**: Currently limited to creating services from **GitHub repositories**. Other sources (like Docker images or databases) are not yet implemented.
- **Authentication**: Requires a valid Railway API Token and Workspace ID to function.

## Getting Started

1. Download/Build the app.
2. Launch Topway (it will appear in your menu bar).
3. Open **Settings**.
4. Enter your **Railway API Token** and **Workspace ID**.
   - *Token*: Generate this in your Railway Account Settings.
   - *Workspace ID*: Press `Cmd + K` in the Railway Dashboard and search for "Copy Active Workspace ID".
