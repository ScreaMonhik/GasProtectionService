//
//  GasProtectionServiceApp.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

@main
struct GasProtectionServiceApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.isLoggedIn {
                    TabBarView()
                        .environmentObject(appState)
                } else {
                    LoginView()
                        .environmentObject(appState)
                }
            }
            .preferredColorScheme(appState.theme.colorScheme)
        }
    }
}
