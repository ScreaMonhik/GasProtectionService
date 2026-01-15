//
//  OperationWorkController.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import Foundation
import Combine
import SwiftUI

class OperationWorkController: NSObject, ObservableObject {
    @Published var workData: OperationWorkData
    @Published var showingAddressAlert = false
    @Published var showingTeamInfo = false
    
    // Location service properties
    var currentAddress: String {
        locationService.currentAddress
    }
    
    var isLoadingLocation: Bool {
        locationService.isLoadingLocation
    }
    @Published var showingPressureAlert = false
    @Published var pressureAlertMessage = ""
    @Published var showingConsumptionWarning = false
    @Published var consumptionWarningMessage = ""
    
    private var scenePhaseObserver: NSObjectProtocol?
    
    // Services
    private let notificationService = TimerNotificationService.shared
    let locationService = LocationService.shared
    private weak var appState: AppState?
    
    // Callback для алертов вместо @Published
    var onValidationError: ((String) -> Void)?
    var alertAlreadyShown = false  // Internal access for View
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Work Calculation Constants (згідно з методичними рекомендаціями)
    private let reservDrager = 50  // резерв для Drager аппаратов (50-60 бар для сигнального пристрою)
    private let reservASV = 30     // резерв для ASP-2 аппарата
    
    init(operationData: OperationData, appState: AppState? = nil) {
        // Временная инициализация workData
        var tempWorkData = OperationWorkData(operationData: operationData)
        self.workData = tempWorkData
        self.appState = appState
        super.init()
        
        // Рассчитываем начальные параметры
        let minPressure = GasCalculator.getMinPressureInTeam(from: operationData.members)
        let protectionTime = GasCalculator.calculateProtectionTime(minPressure: minPressure, deviceType: operationData.deviceType)
        let remainingTimer = TimeInterval(protectionTime * 60)
        let exitTimer = TimeInterval(protectionTime / 2 * 60)
        
        print("⚙️ Initial calculations for \(operationData.deviceType.displayName):")
        print("   minPressure=\(minPressure), protectionTime=\(protectionTime)")
        print("   remainingTimer=\(remainingTimer), exitTimer=\(exitTimer)")
        
        // Создаем OperationWorkData с рассчитанными значениями
        var workData = OperationWorkData(
            operationData: operationData,
            protectionTime: protectionTime,
            minPressure: minPressure,
            remainingTimer: remainingTimer,
            exitTimer: exitTimer
        )
        
        // Розраховуємо критичний тиск та інші параметри згідно з методичними рекомендаціями
        workData.criticalPressure = Int(GasCalculator.calculateCriticalPressure(
            pIncl: Double(workData.minPressure),
            pRez: operationData.deviceType.reservePressure
        ))
        workData.hoodPressure = Int(GasCalculator.calculateHoodPressure(
            pIncl: Double(workData.minPressure),
            pStartWork: Double(workData.criticalPressure),
            isVictimHelping: false,
            pRez: operationData.deviceType.reservePressure
        ))
        workData.evacuationTimeWithVictim = GasCalculator.calculateEvacuationTimeWithVictim(
            minPressure: workData.minPressure,
            deviceType: operationData.deviceType,
            workMode: workData.workMode
        )
        
        self.workData = workData
        
        print("🎯 Created OperationWorkData with remainingTimer = \(self.workData.remainingTimer)")
        
        // Добавляем операцию в активные
        addToActiveOperations()
        
        // Настраиваем отслеживание фазы приложения
        setupScenePhaseObserver()
        
        // Начальное давление будет установлено при начале работы в НДС
        var updatedWorkData = workData
        updatedWorkData.minPressure = getMinPressureInTeam()
        
        // Рассчитываем время защитной работы аппарата
        updatedWorkData.protectionTime = GasCalculator.calculateProtectionTime(
            minPressure: updatedWorkData.minPressure,
            deviceType: operationData.deviceType
        )
        
        // Розраховуємо критичний тиск та інші параметри згідно з методичними рекомендаціями
        updatedWorkData.criticalPressure = Int(GasCalculator.calculateCriticalPressure(
            pIncl: Double(updatedWorkData.minPressure),
            pRez: operationData.deviceType.reservePressure
        ))
        updatedWorkData.hoodPressure = Int(GasCalculator.calculateHoodPressure(
            pIncl: Double(updatedWorkData.minPressure),
            pStartWork: Double(updatedWorkData.criticalPressure),
            isVictimHelping: false,
            pRez: operationData.deviceType.reservePressure
        ))
        updatedWorkData.evacuationTimeWithVictim = GasCalculator.calculateEvacuationTimeWithVictim(
            minPressure: updatedWorkData.minPressure,
            deviceType: operationData.deviceType,
            workMode: updatedWorkData.workMode
        )
        
        // Устанавливаем таймеры на основе расчетов
        print("⚙️ Initial calculations for \(operationData.deviceType.displayName): protectionTime=\(updatedWorkData.protectionTime), minPressure=\(updatedWorkData.minPressure)")
        print("   Device params: cylinders=\(operationData.deviceType.cylinderCount), volume=\(operationData.deviceType.cylinderVolume), reserve=\(operationData.deviceType.reservePressure)")
        print("   Device airConsumption=\(operationData.deviceType.airConsumption)")
        
        updatedWorkData.protectionTime = GasCalculator.calculateProtectionTime(minPressure: updatedWorkData.minPressure, deviceType: operationData.deviceType)
        
        print("🔧 After calculateProtectionTime: protectionTime = \(updatedWorkData.protectionTime)")
        
        let calculatedRemaining = TimeInterval(updatedWorkData.protectionTime * 60)
        let calculatedExit = TimeInterval(updatedWorkData.protectionTime / 2 * 60)
        
        print("⏰ Calculated timers: protectionTime=\(updatedWorkData.protectionTime), calculatedRemaining=\(calculatedRemaining) seconds (\(calculatedRemaining/60) min), calculatedExit=\(calculatedExit) seconds (\(calculatedExit/60) min)")
        print("🔍 Before setting: updatedWorkData.remainingTimer = \(updatedWorkData.remainingTimer)")
        
        print("🔧 Setting remainingTimer to \(calculatedRemaining)")
        updatedWorkData.remainingTimer = calculatedRemaining
        updatedWorkData.exitTimer = calculatedExit
        
        print("✅ After setting: updatedWorkData.remainingTimer = \(updatedWorkData.remainingTimer)")
        print("📋 Final updatedWorkData: protectionTime=\(updatedWorkData.protectionTime), remainingTimer=\(updatedWorkData.remainingTimer)")
        
        workData = updatedWorkData
        
        print("🔄 After workData = updatedWorkData: workData.remainingTimer = \(workData.remainingTimer)")
        
        self.workData = workData
        
        print("🎯 Final self.workData.remainingTimer = \(self.workData.remainingTimer)")
        
        workData = updatedWorkData
        
        self.workData = workData
        
        print("🎯 OperationWorkController initialized with remainingTimer = \(self.workData.remainingTimer)")
        
        // Планируем уведомления для начальных таймеров
        scheduleAllTimerNotifications()
    }
    
    // Инициализатор для работы с существующей операцией
    init(existingOperation: OperationWorkData, appState: AppState) {
        self.workData = existingOperation
        self.appState = appState
        super.init()
        
        // Настраиваем отслеживание фазы приложения
        setupScenePhaseObserver()
    }
    
    
    func setAppState(_ appState: AppState) {
        self.appState = appState
        setupSubscriptions()
    }
    
    
    // Настройка подписок на обновление состояния
    private func setupSubscriptions() {
        guard let appState = appState else { return }
        
        // Подписываемся на изменения в ActiveOperationsManager
        appState.activeOperationsManager.$activeOperations
            .receive(on: RunLoop.main)
            .sink { [weak self] operations in
                self?.handleActiveOperationsUpdate(operations)
            }
            .store(in: &cancellables)
    }
    
    // Обработка обновлений от менеджера
    private func handleActiveOperationsUpdate(_ operations: [OperationWorkData]) {
        // Ищем нашу операцию в списке
        guard let updatedOperation = operations.first(where: { $0.id == workData.id }) else {
            return
        }
        
        let oldWorkData = workData
        
        // Обновляем таймеры и другие изменяющиеся поля
        if workData.exitTimer != updatedOperation.exitTimer ||
            workData.remainingTimer != updatedOperation.remainingTimer ||
            workData.communicationTimer != updatedOperation.communicationTimer {
            
            workData.exitTimer = updatedOperation.exitTimer
            workData.remainingTimer = updatedOperation.remainingTimer
            workData.communicationTimer = updatedOperation.communicationTimer
        }
        
        // Проверяем, нужно ли проиграть звуки (теперь это вызывается при каждом обновлении)
        checkForTimerSounds(oldWorkData: oldWorkData, newWorkData: updatedOperation)
    }
    
    // ... [loadCurrentDataFromManager and saveChangesToManager remain similar] ...
    
    // ...
    
    // ...
    
    private func checkForTimerSounds(oldWorkData: OperationWorkData, newWorkData: OperationWorkData, playSounds: Bool = true) {
        // Проигрываем звук если таймеры достигли нуля (переход от >0 к 0)
        // И если разрешено проигрывание звуков (playSounds)
        if playSounds,
           ((oldWorkData.exitTimer > 0 && newWorkData.exitTimer <= 0) ||
            (oldWorkData.remainingTimer > 0 && newWorkData.remainingTimer <= 0) ||
            (oldWorkData.communicationTimer > 0 && newWorkData.communicationTimer <= 0)) {
            
            print("🔊 Timer finished! Playing sound.")
            notificationService.playAlertSound()
        }
        
        // Логика перепланирования уведомлений
        // Мы не хотим перепланировать уведомления каждую секунду, когда таймер просто тикает.
        // Перепланируем только если время изменилось "нестандартно" (не на 1 секунду)
        // или если таймеры были установлены/сброшены
        
        let exitDiff = abs(newWorkData.exitTimer - (oldWorkData.exitTimer - 1))
        let remainingDiff = abs(newWorkData.remainingTimer - (oldWorkData.remainingTimer - 1))
        let commDiff = abs(newWorkData.communicationTimer - (oldWorkData.communicationTimer - 1))
        
        // Если отличие больше 2 секунд (с запасом на лаги) или таймер стал 0, считаем это "значимым" изменением
        let isSignificantChange = exitDiff > 2 || remainingDiff > 2 || commDiff > 2
        
        // Также перепланируем, если таймеры только что установили (было 0, стало > 0)
        let isNewTimer = (oldWorkData.exitTimer <= 0 && newWorkData.exitTimer > 0) ||
                         (oldWorkData.remainingTimer <= 0 && newWorkData.remainingTimer > 0)
        
        if isSignificantChange || isNewTimer {
            print("📅 Rescheduling notifications due to significant timer change")
            cancelAllTimerNotifications()
            scheduleAllTimerNotifications()
        }
    }
    
    // Загрузка актуальных данных из менеджера (при переключении на операцию)
    func loadCurrentDataFromManager(playSounds: Bool = true) {
        guard let appState = appState,
              let currentOperation = appState.activeOperationsManager.currentOperation else {
            return
        }
        
        print("🔄 Loading data from manager for operation: \(currentOperation.operationData.commandName ?? currentOperation.operationData.operationType.displayName)")
        print("🔄 Current operation remainingTimer: \(currentOperation.remainingTimer)")
        print("🔄 Current operation minPressure: \(currentOperation.minPressure)")
        
        // Сначала сохраняем текущие изменения в менеджер
        // ОШИБКА: Нельзя сохранять здесь, иначе мы перезапишем таймеры, которые менеджер уже обновил в фоне!
        // appState.activeOperationsManager.updateActiveOperation(workData)
        
        let oldWorkData = workData
        // Всегда загружаем данные текущей операции, независимо от ID
        workData = currentOperation
        
        print("✅ Loaded data. New remainingTimer: \(workData.remainingTimer), minPressure: \(workData.minPressure)")
        
        // Проверяем, нужно ли проиграть звуки
        checkForTimerSounds(oldWorkData: oldWorkData, newWorkData: currentOperation, playSounds: playSounds)
        
        // Удалено recalculateInitialParameters, так как это сбрасывает таймеры
        // recalculateInitialParameters()
    }
    
    // Сохранение изменений в менеджер операций
    func saveChangesToManager() {
        guard let appState = appState else { return }
        appState.activeOperationsManager.updateActiveOperation(workData)
    }
    
    
    // Пересчет начальных параметров (для случаев изменения данных команды)
    func recalculateInitialParameters() {
        print("🔄 Recalculating initial parameters")
        var updatedWorkData = workData
        
        updatedWorkData.minPressure = getMinPressureInTeam()
        updatedWorkData.protectionTime = GasCalculator.calculateProtectionTime(
            minPressure: updatedWorkData.minPressure,
            deviceType: workData.operationData.deviceType
        )
        
        // Пересчитываем критичний тиск та інші параметри
        updatedWorkData.criticalPressure = Int(GasCalculator.calculateCriticalPressure(
            pIncl: Double(updatedWorkData.minPressure),
            pRez: workData.operationData.deviceType.reservePressure
        ))
        
        // Обновляем таймеры
        let oldRemaining = updatedWorkData.remainingTimer
        updatedWorkData.remainingTimer = TimeInterval(updatedWorkData.protectionTime * 60)
        updatedWorkData.exitTimer = TimeInterval(updatedWorkData.protectionTime / 2 * 60)
        
        workData = updatedWorkData
        
        print("✅ Recalculated: minPressure=\(updatedWorkData.minPressure), protectionTime=\(updatedWorkData.protectionTime)")
        print("⏰ Updated timers: remainingTimer \(oldRemaining) -> \(updatedWorkData.remainingTimer)")
        
        saveChangesToManager()
    }
    
    // Обновление только таймеров (для глобального таймера)
    func updateTimersFromGlobal() {
        guard let appState = appState,
              let currentOperation = appState.activeOperationsManager.currentOperation else {
            return
        }
        
        // Обновляем только таймеры, без изменения всей workData
        let oldExitTimer = workData.exitTimer
        let oldRemainingTimer = workData.remainingTimer
        let oldCommunicationTimer = workData.communicationTimer
        
        workData.exitTimer = currentOperation.exitTimer
        workData.remainingTimer = currentOperation.remainingTimer
        workData.communicationTimer = currentOperation.communicationTimer
        
        // Проверяем звуки
        if (oldExitTimer > 0 && currentOperation.exitTimer == 0) ||
            (oldRemainingTimer > 0 && currentOperation.remainingTimer == 0) ||
            (oldCommunicationTimer > 0 && currentOperation.communicationTimer == 0) {
            notificationService.playAlertSound()
        }
    }
    

    
    // Проверка и удаление завершенной операции
    func checkAndRemoveCompletedOperation() {
        guard let appState = appState else { return }
        
        // Операция считается завершенной, если она вышла из зоны опасности и сохранен адрес
        if workData.isExitingDangerZone && !workData.workAddress.isEmpty {
            appState.activeOperationsManager.removeActiveOperation(withId: workData.id)
        }
    }
    
    private func addToActiveOperations() {
        guard let appState = appState else { return }
        appState.activeOperationsManager.addActiveOperation(workData)
    }
    
    private func updateActiveOperation() {
        guard let appState = appState else { return }
        appState.activeOperationsManager.updateActiveOperation(workData)
    }
    
    
    deinit {
        cancelAllTimerNotifications()
        if let observer = scenePhaseObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupScenePhaseObserver() {
        // Наблюдаем за изменением фазы сцены через NotificationCenter
        // Так как мы не можем напрямую использовать onChange в NSObject
        scenePhaseObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleScenePhaseChange(.background)
        }
        
        // Также добавляем наблюдатель для активного состояния
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleScenePhaseChange(.active)
        }
    }
    
    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Приложение уходит в фон, таймеры продолжают работать в ActiveOperationsManager
            print("📱 App entered background. Delegating to Manager.")
            appState?.activeOperationsManager.handleScenePhaseChange(.background)
            
            // ПЕРЕСТРАХОВКА: Принудительно обновляем уведомления перед уходом в фон
            // Это гарантирует, что уведомление запланировано с актуальным временем
            cancelAllTimerNotifications()
            scheduleAllTimerNotifications()
            print("🔔 Force scheduled notifications before background")
            
            saveChangesToManager()
            
        case .active:
            // Приложение возвращается из фона
            print("📱 App became active. Delegating to Manager.")
            appState?.activeOperationsManager.handleScenePhaseChange(.active)
            
            // Синхронизируем состояние с менеджером (он мог обновить таймеры)
            // Важно: менеджер уже обновил таймеры в handleScenePhaseChange(.active)
            // НЕ проигрываем звук, так как уведомление уже было отправлено, а пользователь просто открыл приложение
            loadCurrentDataFromManager(playSounds: false)
            
        case .inactive:
            break
            
        @unknown default:
            break
        }
    }
    
    
    func findFireSource() {
        var updatedWorkData = workData
        updatedWorkData.hasFoundFireSource = true
        updatedWorkData.fireSourceFoundTime = Date()
        
        // Рассчитываем время поиска очага в минутах
        if let entryTime = workData.operationData.settings.entryTime,
           let foundTime = updatedWorkData.fireSourceFoundTime {
            let searchTimeInterval = foundTime.timeIntervalSince(entryTime)
            updatedWorkData.searchTime = Int(searchTimeInterval / 60) // в минутах
        }
        workData = updatedWorkData
        
        // Сохраняем изменения
        saveChangesToManager()
    }
    
    /// Получить минимальное давление среди активных членов ланки
    func getMinPressureInTeam() -> Int {
        let activeMembers = workData.operationData.members.filter { $0.isActive }
        let pressures = activeMembers.compactMap { Int($0.pressure) }
        let minPressure = pressures.min() ?? 0
        print("👥 Team pressures: \(pressures) from members: \(activeMembers.map { $0.fullName + ":\($0.pressure)" }), minPressure: \(minPressure)")
        return minPressure
    }
    
    /// Получить минимальное давление из operationData (статический расчет)
    static func getMinPressureInTeam(from operationData: OperationData) -> Int {
        let activeMembers = operationData.members.filter { $0.isActive }
        let pressures = activeMembers.compactMap { Int($0.pressure) }
        return pressures.min() ?? 0
    }
    
    /// Factory method to create correctly initialized OperationWorkData
    static func createInitialWorkData(from operationData: OperationData) -> OperationWorkData {
        print("🏭 Factory creating WorkData for \(operationData.deviceType.displayName)...")
        
        // Используем хелпер для получения минимального давления
        let activeMembers = operationData.members.filter { $0.isActive }
        let pressures = activeMembers.compactMap { Int($0.pressure) }
        let minPressure = pressures.min() ?? 0
        
        let protectionTime = GasCalculator.calculateProtectionTime(minPressure: minPressure, deviceType: operationData.deviceType)
        
        print("   Factory calculations: minPressure=\(minPressure), protectionTime=\(protectionTime)")
        
        let remainingTimer = TimeInterval(protectionTime * 60)
        let exitTimer = TimeInterval(protectionTime / 2 * 60)
        
        var workData = OperationWorkData(
            operationData: operationData,
            protectionTime: protectionTime,
            minPressure: minPressure,
            remainingTimer: remainingTimer,
            exitTimer: exitTimer
        )
        
        // Дополнительные расчеты
        workData.criticalPressure = Int(GasCalculator.calculateCriticalPressure(
            pIncl: Double(minPressure),
            pRez: operationData.deviceType.reservePressure
        ))
        
        workData.hoodPressure = Int(GasCalculator.calculateHoodPressure(
            pIncl: Double(minPressure),
            pStartWork: Double(workData.criticalPressure),
            isVictimHelping: false,
            pRez: operationData.deviceType.reservePressure
        ))
        
        workData.evacuationTimeWithVictim = GasCalculator.calculateEvacuationTimeWithVictim(
            minPressure: minPressure,
            deviceType: operationData.deviceType,
            workMode: workData.workMode
        )
        
        print("✅ Factory WorkData created with remainingTimer = \(workData.remainingTimer)")
        
        return workData
    }
    
    /// Получить минимальный порог давления для типа аппарата
    func getMinPressureThreshold(for deviceType: DeviceType) -> Int {
        switch deviceType {
        case .dragerPSS3000, .dragerPSS4000, .msa:
            return 200  // Минимум для Drager и MSA аппаратов
        case .asp2:
            return 140  // Минимум для АСП-2
        }
    }
    
    func startWorkInDangerZone() {
        print("🚀 Starting work in danger zone. lowestPressure: \(workData.lowestPressure)")
        
        // Защита от повторного выполнения, если алерт уже показан
        if alertAlreadyShown {
            return
        }
        
        let minPressureNearFire = Int(workData.lowestPressure) ?? 0
        print("📊 minPressureNearFire: \(minPressureNearFire)")
        
        // Обновляем минимальное давление в команде
        var updatedWorkData = workData
        updatedWorkData.minPressure = getMinPressureInTeam()
        
        // Устанавливаем начальное давление на момент начала работы в НДС
        updatedWorkData.initialMinPressure = updatedWorkData.minPressure
        
        // Валидация: давление у огня не может быть больше минимального давления в команде
        let minTeamPressure = updatedWorkData.minPressure
        if minPressureNearFire > minTeamPressure {
            if !alertAlreadyShown {
                pressureAlertMessage = "Тиск біля вогню не може бути більше початкового тиску"
                showingPressureAlert = true
                alertAlreadyShown = true
            }
            return
        }
        
        // Валидация: давление у огня не может быть ниже минимального порога для аппарата
        let minPressureThreshold = getMinPressureThreshold(for: workData.operationData.deviceType)
        if minPressureNearFire < minPressureThreshold {
            if !alertAlreadyShown {
                pressureAlertMessage = "Найменший тиск в ланці не може бути менше \(minPressureThreshold) бар для даного типу апарату"
                showingPressureAlert = true
                alertAlreadyShown = true
            }
            return
        }
        
        updatedWorkData.isWorkingInDangerZone = true
        updatedWorkData.dangerZoneStartTime = Date()
        
        // Выполняем расчеты для работы в опасной зоне
        if minPressureNearFire > 0 {
            // Рассчитываем реальный расход воздуха на основе времени поиска очага
            let actualAirConsumption = GasCalculator.calculateActualAirConsumption(
                initialPressure: updatedWorkData.initialMinPressure,
                currentPressure: minPressureNearFire,
                searchTimeMinutes: Double(workData.searchTime),
                deviceType: workData.operationData.deviceType
            )
            
            // Проверка на потребление для предупреждения (sheet)
            let maxConsumption = workData.operationData.deviceType.airConsumption * 2.0
            if actualAirConsumption > maxConsumption {
                consumptionWarningMessage = "⚠️ УВАГА: Висока витрата повітря! \n(\(Int(actualAirConsumption)) л/хв) \n\nПеревірте щільність прилягання маски та зʼєднань апарату."
                showingConsumptionWarning = true
            }
            
            // Рассчитываем давление на пути
            // P_пр = P_вкл - P_раб
            let pressureOnPath = updatedWorkData.initialMinPressure - minPressureNearFire
            updatedWorkData.pressureOnPath = pressureOnPath
            
            // Рассчитываем "тиск початку виходу з НДС"
            let exitStartPressure = GasCalculator.calculateExitStartPressure(
                minPressure: workData.initialMinPressure,
                pressureAtWork: minPressureNearFire,
                deviceType: workData.operationData.deviceType
            )
            
            
            // Рассчитываем время работы у очага: время от текущего давления до "тиску початку виходу"
            let pressureDifference = Double(minPressureNearFire) - Double(exitStartPressure)
            if pressureDifference > 0 {
                let nBal = Double(workData.operationData.deviceType.cylinderCount)
                let vBal = Double(workData.operationData.deviceType.cylinderVolume)
                let pAtm = 1.0
                updatedWorkData.workTime = Int(GasCalculator.calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: pressureDifference, qVitr: actualAirConsumption, pAtm: pAtm))
            } else {
                updatedWorkData.workTime = 0 // Давление уже ниже порога выхода
            }
            
            // Запускаем таймер работы у очага
            updatedWorkData.exitTimer = TimeInterval(updatedWorkData.workTime * 60)
            
            // Пересчитываем таймер "Залишок" с учетом реального расхода кислорода
            let remainingPressure = Double(minPressureNearFire) - Double(workData.operationData.deviceType.reservePressure)
            if remainingPressure > 0 {
                let nBal = Double(workData.operationData.deviceType.cylinderCount)
                let vBal = Double(workData.operationData.deviceType.cylinderVolume)
                let remainingTimeMinutes = GasCalculator.calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: remainingPressure, qVitr: actualAirConsumption, pAtm: 1.0)
                updatedWorkData.remainingTimer = TimeInterval(remainingTimeMinutes * 60)
            } else {
                updatedWorkData.remainingTimer = 0
            }
            
            // Планируем уведомления для всех таймеров
            scheduleAllTimerNotifications()
            
            // Устанавливаем время выхода: время начала работы у очага + время работы у очага
            // Когда давление достигнет "тиску початку виходу", нужно начинать выход
            let exitTime = Date()
            updatedWorkData.dangerZoneStartTime = exitTime
            updatedWorkData.dangerZoneExitTime = exitTime.addingTimeInterval(TimeInterval(updatedWorkData.workTime * 60))
        }
        workData = updatedWorkData
        
        print("✅ Work in danger zone completed. New remainingTimer: \(workData.remainingTimer), exitTimer: \(workData.exitTimer)")
        
        // Сохраняем изменения
        saveChangesToManager()
        print("💾 Changes saved to manager")
    }
    
    func startExitFromDangerZone() {
        var updatedWorkData = workData
        updatedWorkData.isExitingDangerZone = true
        workData = updatedWorkData
        
        // Сохраняем изменения
        saveChangesToManager()
    }
    
    func getCurrentLocation() {
        locationService.requestCurrentLocation()
    }
    
    func saveToJournal() -> CheckCommand {
        // Create journal entry with all collected data
        let command = CheckCommand(
            commandName: workData.operationData.operationType.displayName,
            deviceType: workData.operationData.deviceType,
            teamMembers: workData.operationData.members.filter { $0.isActive }.map { member in
                TeamMember(
                    fullName: member.fullName,
                    pressure: member.pressure,
                    hasRescueDevice: false
                )
            },
            commandType: .operation,
            workAddress: workData.workAddress
        )
        
        // Add work data to command if needed
        // For now, we'll store it in UserDefaults with the command ID
        saveWorkDataForCommand(command.id)
        
        return command
    }
    
    private func saveWorkDataForCommand(_ commandId: UUID) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(workData) {
            UserDefaults.standard.set(data, forKey: "operation_work_\(commandId.uuidString)")
        }
    }
    
    static func loadWorkDataForCommand(_ commandId: UUID) -> OperationWorkData? {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "operation_work_\(commandId.uuidString)"),
           let workData = try? decoder.decode(OperationWorkData.self, from: data) {
            return workData
        }
        return nil
    }
    
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    /// Добавить минуты к времени
    func addMinutesToTime(timeString: String, minutes: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let date = formatter.date(from: timeString) else {
            return timeString
        }
        
        let newDate = date.addingTimeInterval(TimeInterval(minutes * 60))
        return formatter.string(from: newDate)
    }
        
        

        
        
        
        
    /// Планирует уведомления для всех активных таймеров
    func scheduleAllTimerNotifications() {
        let exitTime = TimeInterval(workData.exitTimer)
        let remainingTime = TimeInterval(workData.remainingTimer)
        let communicationTime = TimeInterval(workData.communicationTimer)
        
        // Проверяем, есть ли активные таймеры
        guard exitTime > 0 || remainingTime > 0 || communicationTime > 0 else {
            print("No active timers to schedule notifications")
            return
        }
        
        notificationService.scheduleAllTimerNotifications(
            exitTime: exitTime,
            remainingTime: remainingTime,
            communicationTime: communicationTime
        )
    }
    
    /// Отменяет все запланированные уведомления таймеров
    func cancelAllTimerNotifications() {
        notificationService.cancelAllTimerNotifications()
    }
}
