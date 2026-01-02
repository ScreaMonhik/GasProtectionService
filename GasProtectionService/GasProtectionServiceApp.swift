//
//  GasProtectionServiceApp.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI
import UserNotifications

@main
struct GasProtectionServiceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

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
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    appDelegate.applicationDidBecomeActive(UIApplication.shared)
                }
            }
        }
    }
}
