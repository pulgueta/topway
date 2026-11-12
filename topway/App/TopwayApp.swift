//
//  topwayApp.swift
//  topway
//
//  Created by Andrés Rodríguez on 1/15/26.
//

import SwiftUI
import UserNotifications

@main
@MainActor
struct TopwayApp: App {
    @State private var appState = AppState()
    /// The notification center keeps a weak reference, so the app keeps this one.
    private let notificationPresenter = NotificationPresenter()

    init() {
        UNUserNotificationCenter.current().delegate = notificationPresenter
    }

    var body: some Scene {
        MenuBarExtra {
            MainView()
                .environment(appState)
        } label: {
            // The label shows at launch, so the refresh does not wait for the popover.
            MenuBarLabel(health: appState.health)
                .task {
                    await appState.initializeAutoRefresh()
                }
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh Projects") {
                    Task { await appState.loadProjects() }
                }
                .keyboardShortcut("r", modifiers: .command)
                // A rejected token fails again on each refresh. The error screen offers
                // Sign in again and sample data, as the Refresh button of the projects does.
                .disabled(!appState.isConfigured || appState.isTokenRejected || appState.isLoading)
            }
        }

        // Native preferences window (⌘, is added automatically).
        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
