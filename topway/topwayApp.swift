//
//  topwayApp.swift
//  topway
//
//  Created by Andrés Rodríguez on 1/15/26.
//

import SwiftUI

@main
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
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appState.showingSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            CommandGroup(after: .appInfo) {
                Button("Refresh Projects") {
                    Task { await appState.loadProjects() }
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!appState.isConfigured || appState.isLoading)
            }
        }
    }
}
