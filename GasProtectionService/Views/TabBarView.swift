//
//  TabBarView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var controller = MainScreenController()
    private let sideMenuController = SideMenuController()

    private var currentTabTitle: String {
        switch controller.selectedTab {
        case .journal:
            return "Журнал"
        case .check1:
            return "Перевірка №1"
        case .operations:
            return "Оперативна Робота"
        case .qrScanner:
            return "QR-сканер"
        case .checkpoint:
            return "КПП"
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            controller.toggleSideMenu()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text(currentTabTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    // Theme toggle button
                    Button(action: {
                        appState.theme.toggle()
                    }) {
                        Image(systemName: appState.theme == .dark ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground).opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.gray.opacity(0.3)),
                    alignment: .bottom
                )

                // Tab View
                TabView(selection: $controller.selectedTab) {
                    JournalView()
                        .tabItem {
                            Label("Журнал", systemImage: "book.fill")
                        }
                        .tag(Tab.journal)

                    Check1View()
                        .tabItem {
                            Label("Перевірка №1", systemImage: "checkmark.circle")
                        }
                        .tag(Tab.check1)

                    OperationsView()
                        .tabItem {
                            Label("Опер. Робота", systemImage: "wrench.and.screwdriver")
                        }
                        .tag(Tab.operations)

                    QRScannerView()
                        .tabItem {
                            Label("QR-сканер", systemImage: "qrcode.viewfinder")
                        }
                        .tag(Tab.qrScanner)

                    CheckpointView()
                        .tabItem {
                            Label("КПП", systemImage: "building.2")
                        }
                        .tag(Tab.checkpoint)
                }
                .accentColor(.blue)
            }

            // Side Menu Overlay
            if controller.showSideMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            controller.hideSideMenu()
                        }
                    }

                SideMenuView(isShowing: $controller.showSideMenu, controller: sideMenuController)
                    .frame(width: 280)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    TabBarView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark) // Preview с темной темой
}
