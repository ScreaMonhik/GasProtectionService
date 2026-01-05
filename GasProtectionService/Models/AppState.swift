//
//  AppState.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Active Operation Manager
class ActiveOperationsManager: ObservableObject {
    private let activeOperationsKey = "active_operations"

    private var _activeOperations: [OperationWorkData] = [] {
        didSet {
            saveActiveOperations()
        }
    }

    var activeOperations: [OperationWorkData] {
        _activeOperations
    }

    // Глобальный таймер для обновления всех активных операций
    private var globalTimer: Timer?
    private var backgroundTime: Date?

    init() {
        startGlobalTimer()
        loadActiveOperations()

        // Очищаем активные операции при запуске приложения (они не должны сохраняться между запусками)
        if !_activeOperations.isEmpty {
            print("🧹 Clearing \(_activeOperations.count) active operations on app launch")
            _activeOperations.removeAll()
            currentOperationId = nil
            saveActiveOperations()
        }
    }

    deinit {
        globalTimer?.invalidate()
    }

    private func startGlobalTimer() {
        globalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateAllActiveOperations()
        }
    }

    private func updateAllActiveOperations() {
        for (index, operation) in _activeOperations.enumerated() {
            var updatedOperation = operation

            // Обновляем таймеры
            if updatedOperation.exitTimer > 0 {
                updatedOperation.exitTimer -= 1
            }
            if updatedOperation.remainingTimer > 0 {
                updatedOperation.remainingTimer -= 1
            }
            if updatedOperation.communicationTimer > 0 {
                updatedOperation.communicationTimer -= 1
            }

            _activeOperations[index] = updatedOperation
        }
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            backgroundTime = Date()
        case .active:
            if let backgroundStart = backgroundTime {
                let timeInBackground = Date().timeIntervalSince(backgroundStart)
                adjustTimersAfterBackground(timeInBackground)
            }
            backgroundTime = nil
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func adjustTimersAfterBackground(_ timeInBackground: TimeInterval) {
        for (index, operation) in _activeOperations.enumerated() {
            var updatedOperation = operation

            // Корректируем таймеры (вычитаем время проведенное в фоне)
            if updatedOperation.exitTimer > timeInBackground {
                updatedOperation.exitTimer -= timeInBackground
            } else {
                updatedOperation.exitTimer = 0
            }

            if updatedOperation.remainingTimer > timeInBackground {
                updatedOperation.remainingTimer -= timeInBackground
            } else {
                updatedOperation.remainingTimer = 0
            }

            if updatedOperation.communicationTimer > timeInBackground {
                updatedOperation.communicationTimer -= timeInBackground
            } else {
                updatedOperation.communicationTimer = 0
            }

            _activeOperations[index] = updatedOperation
        }
    }

    @Published var currentOperationId: UUID?

    var currentOperation: OperationWorkData? {
        _activeOperations.first { $0.id == currentOperationId }
    }

    func addActiveOperation(_ operation: OperationWorkData) {
        _activeOperations.append(operation)
        print("Added active operation: \(operation.operationData.commandName ?? "Unknown") at \(Date())")
        print("Total active operations: \(_activeOperations.count)")
        // Если это первая операция, сделать её текущей
        if _activeOperations.count == 1 {
            currentOperationId = operation.id
        }
    }

    func removeActiveOperation(withId id: UUID) {
        _activeOperations.removeAll { $0.id == id }
        // Если удалили текущую операцию, выбрать другую
        if currentOperationId == id {
            currentOperationId = _activeOperations.first?.id
        }
    }

    func switchToOperation(withId id: UUID) {
        if _activeOperations.contains(where: { $0.id == id }) {
            currentOperationId = id
        }
    }

    func updateActiveOperation(_ operation: OperationWorkData) {
        if let index = _activeOperations.firstIndex(where: { $0.id == operation.id }) {
            _activeOperations[index] = operation
        }
    }

    private func saveActiveOperations() {
        do {
            let data = try JSONEncoder().encode(activeOperations)
            UserDefaults.standard.set(data, forKey: activeOperationsKey)
        } catch {
            print("Error saving active operations: \(error)")
        }
    }

    private func loadActiveOperations() {
        guard let data = UserDefaults.standard.data(forKey: activeOperationsKey) else { return }
        do {
            _activeOperations = try JSONDecoder().decode([OperationWorkData].self, from: data)
        } catch {
            print("Error loading active operations: \(error)")
        }
    }
}

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

    @Published var isLoggedIn = true // Поменять на false чтобы отображать экран регистрации
    @Published var currentUser: User?
    @Published var checkController = CheckController()
    @Published var activeOperationsManager = ActiveOperationsManager()

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

        // activeOperationsManager больше не ObservableObject
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
