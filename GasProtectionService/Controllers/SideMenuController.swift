//
//  SideMenuController.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import Foundation
import Combine

class SideMenuController: ObservableObject {
    // MARK: - Menu Items Model

    struct MenuItem {
        let id: String
        let icon: String
        let title: String
        let action: MenuAction
    }

    enum MenuAction {
        case logout
        case help
        case about
    }

    // MARK: - Callbacks
    var onShowAboutApp: (() -> Void)?

    // MARK: - Properties

    let menuItems: [MenuItem] = [
        MenuItem(id: "logout", icon: "arrow.right.square", title: "Вийти з аккаунту", action: .logout),
        MenuItem(id: "help", icon: "questionmark.circle", title: "Довідник", action: .help),
        MenuItem(id: "about", icon: "questionmark.circle", title: "Про додаток", action: .about)
    ]

    // MARK: - Public Methods

    func handleMenuItemTap(_ item: MenuItem) {
        switch item.action {
        case .logout:
            print("Logout user")
        case .help:
            print("Navigate to help")
        case .about:
            print("About menu item tapped, calling callback")
            onShowAboutApp?()
            print("Callback called")
        }
    }
}
