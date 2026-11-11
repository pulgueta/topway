//
//  topwayApp.swift
//  topway
//
//  Created by Andrés Rodríguez on 1/15/26.
//

import SwiftUI

@main
@MainActor
struct TopwayApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Topway", systemImage: "tram.fill") {
            MainView()
                .environment(appState)
                .task {
                    appState.initializeAutoRefresh()
                }
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh Projects") {
                    Task { await appState.loadProjects() }
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!appState.isConfigured || appState.isLoading)
            }
        }

        // Native preferences window (⌘, is added automatically).
        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
