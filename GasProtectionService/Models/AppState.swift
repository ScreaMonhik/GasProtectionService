//
//  AppState.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import Foundation
import Combine
import SwiftUI

enum AppTheme: String {
    case light, dark

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }

    mutating func toggle() {
        self = self == .light ? .dark : .light
    }
}

class AppState: ObservableObject {
    private let themeKey = "app_theme"

    @Published var isLoggedIn = false
    @Published var currentUser: User?
    @Published var checkController = CheckController()

    @Published var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        }
    }

    init() {
        // Загружаем сохраненную тему или используем темную по умолчанию
        if let savedThemeRaw = UserDefaults.standard.string(forKey: themeKey),
           let savedTheme = AppTheme(rawValue: savedThemeRaw) {
            self.theme = savedTheme
        } else {
            self.theme = .dark // По умолчанию темная тема
        }

        // Подписываемся на изменения в checkController
        checkController.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Methods

    func login(with user: User) {
        currentUser = user
        isLoggedIn = true
    }

    func logout() {
        currentUser = nil
        isLoggedIn = false
    }
}
