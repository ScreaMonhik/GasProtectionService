//
//  MainScreenController.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import Foundation
import Combine

class MainScreenController: ObservableObject {
    @Published var selectedTab: Tab = .journal
    @Published var showSideMenu = false

    // MARK: - Public Methods

    func toggleSideMenu() {
        showSideMenu.toggle()
    }

    func hideSideMenu() {
        showSideMenu = false
    }

    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }

}

// MARK: - Tab Enum
enum Tab {
    case journal, check1, operations, qrScanner, checkpoint
}
