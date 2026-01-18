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
    }
}
