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
        let minPressure = OperationWorkController.getMinPressureInTeam(from: operationData)
        let protectionTime = OperationWorkController.calculateProtectionTime(minPressure: minPressure, deviceType: operationData.deviceType)
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
        workData.criticalPressure = Int(OperationWorkController.calculateCriticalPressure(
            pIncl: Double(workData.minPressure),
            pRez: operationData.deviceType.reservePressure
        ))
        workData.hoodPressure = Int(OperationWorkController.calculateHoodPressure(
            pIncl: Double(workData.minPressure),
            pStartWork: Double(workData.criticalPressure),
            isVictimHelping: false,
            pRez: operationData.deviceType.reservePressure
        ))
        workData.evacuationTimeWithVictim = OperationWorkController.calculateEvacuationTimeWithVictim(
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
        updatedWorkData.protectionTime = OperationWorkController.calculateProtectionTime(
            minPressure: updatedWorkData.minPressure,
            deviceType: operationData.deviceType
        )

        // Розраховуємо критичний тиск та інші параметри згідно з методичними рекомендаціями
        updatedWorkData.criticalPressure = Int(OperationWorkController.calculateCriticalPressure(
            pIncl: Double(updatedWorkData.minPressure),
            pRez: operationData.deviceType.reservePressure
        ))
        updatedWorkData.hoodPressure = Int(OperationWorkController.calculateHoodPressure(
            pIncl: Double(updatedWorkData.minPressure),
            pStartWork: Double(updatedWorkData.criticalPressure),
            isVictimHelping: false,
            pRez: operationData.deviceType.reservePressure
        ))
        updatedWorkData.evacuationTimeWithVictim = OperationWorkController.calculateEvacuationTimeWithVictim(
            minPressure: updatedWorkData.minPressure,
            deviceType: operationData.deviceType,
            workMode: updatedWorkData.workMode
        )

        // Устанавливаем таймеры на основе расчетов
        print("⚙️ Initial calculations for \(operationData.deviceType.displayName): protectionTime=\(updatedWorkData.protectionTime), minPressure=\(updatedWorkData.minPressure)")
        print("   Device params: cylinders=\(operationData.deviceType.cylinderCount), volume=\(operationData.deviceType.cylinderVolume), reserve=\(operationData.deviceType.reservePressure)")
        print("   Device airConsumption=\(operationData.deviceType.airConsumption)")

        updatedWorkData.protectionTime = OperationWorkController.calculateProtectionTime(minPressure: updatedWorkData.minPressure, deviceType: operationData.deviceType)

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
        // Не начинаем наблюдение, чтобы не мешать sheets
    }

    // Синхронизация данных с менеджером операций
    private func startDataSynchronization() {
        // Синхронизируем данные каждые 5 секунд
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateActiveOperation()
        }
    }

    // Загрузка актуальных данных из менеджера (при переключении на операцию)
    func loadCurrentDataFromManager() {
        guard let appState = appState,
              let currentOperation = appState.activeOperationsManager.currentOperation else {
            return
        }

        print("🔄 Loading data from manager for operation: \(currentOperation.operationData.commandName ?? currentOperation.operationData.operationType.displayName)")
        print("🔄 Current operation remainingTimer: \(currentOperation.remainingTimer)")
        print("🔄 Current operation minPressure: \(currentOperation.minPressure)")

        // Сначала сохраняем текущие изменения в менеджер
        appState.activeOperationsManager.updateActiveOperation(workData)

        let oldWorkData = workData
        // Всегда загружаем данные текущей операции, независимо от ID
        workData = currentOperation

        print("✅ Loaded data. New remainingTimer: \(workData.remainingTimer), minPressure: \(workData.minPressure)")

        // Проверяем, нужно ли проиграть звуки
        checkForTimerSounds(oldWorkData: oldWorkData, newWorkData: currentOperation)

        // Пересчитываем параметры на случай изменений в команде
        recalculateInitialParameters()
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
        updatedWorkData.protectionTime = OperationWorkController.calculateProtectionTime(
            minPressure: updatedWorkData.minPressure,
            deviceType: workData.operationData.deviceType
        )

        // Пересчитываем критичний тиск та інші параметри
        updatedWorkData.criticalPressure = Int(OperationWorkController.calculateCriticalPressure(
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

    private func checkForTimerSounds(oldWorkData: OperationWorkData, newWorkData: OperationWorkData) {
        // Проигрываем звук если таймеры достигли нуля
        if (oldWorkData.exitTimer > 0 && newWorkData.exitTimer == 0) ||
           (oldWorkData.remainingTimer > 0 && newWorkData.remainingTimer == 0) ||
           (oldWorkData.communicationTimer > 0 && newWorkData.communicationTimer == 0) {
            notificationService.playAlertSound()
        }

        // Перепланируем уведомления если таймеры изменились
        if oldWorkData.exitTimer != newWorkData.exitTimer ||
           oldWorkData.remainingTimer != newWorkData.remainingTimer ||
           oldWorkData.communicationTimer != newWorkData.communicationTimer {
            cancelAllTimerNotifications()
            scheduleAllTimerNotifications()
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
        
        let minPressure = getMinPressureInTeam(from: operationData)
        let protectionTime = calculateProtectionTime(minPressure: minPressure, deviceType: operationData.deviceType)
        
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
        workData.criticalPressure = Int(calculateCriticalPressure(
            pIncl: Double(minPressure),
            pRez: operationData.deviceType.reservePressure
        ))
        
        workData.hoodPressure = Int(calculateHoodPressure(
            pIncl: Double(minPressure),
            pStartWork: Double(workData.criticalPressure),
            isVictimHelping: false,
            pRez: operationData.deviceType.reservePressure
        ))
        
        workData.evacuationTimeWithVictim = calculateEvacuationTimeWithVictim(
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
            let actualAirConsumption = calculateActualAirConsumption(
                initialPressure: updatedWorkData.initialMinPressure,
                currentPressure: minPressureNearFire,
                searchTimeMinutes: workData.searchTime,
                deviceType: workData.operationData.deviceType
            )

            // Рассчитываем давление на пути
            updatedWorkData.pressureOnPath = calculatePressureOnPath(
                minPressure: workData.minPressure,
                minPressureNearFire: minPressureNearFire,
                deviceType: workData.operationData.deviceType,
                workMode: workData.workMode

            )

            // Рассчитываем "тиск початку виходу з НДС"
            let exitStartPressure = calculateExitStartPressure(
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
                updatedWorkData.workTime = Int(OperationWorkController.calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: pressureDifference, qVitr: actualAirConsumption, pAtm: pAtm))
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
                let remainingTimeMinutes = OperationWorkController.calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: remainingPressure, qVitr: actualAirConsumption, pAtm: 1.0)
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

    // MARK: - Work Calculations

    /// Рассчитать время защитной работы аппарата (згідно з методичними рекомендаціями)
    static func calculateProtectionTime(minPressure: Int, deviceType: DeviceType) -> Int {
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let pRob = Double(minPressure) - deviceType.reservePressure
        let qVitr = deviceType.airConsumption  // використовуємо расход повітря для даного типу апарата
        let pAtm = 1.0

        print("🔢 Calculating protection time for \(deviceType.displayName):")
        print("   minPressure=\(minPressure), cylinderCount=\(nBal), cylinderVolume=\(vBal), reservePressure=\(deviceType.reservePressure)")
        print("   pRob=\(pRob), qVitr=\(qVitr)")

        let numerator = nBal * vBal * pRob
        let denominator = qVitr * pAtm
        let time = numerator / denominator

        print("   Calculation: (\(nBal) * \(vBal) * \(pRob)) / (\(qVitr) * \(pAtm)) = \(numerator) / \(denominator) = \(time) minutes")
        return Int(time)
    }

    /// Расчет времени работы (новая формула из Gemini)
    static func calculateWorkTimeAir(nBal: Double, vBal: Double, pRob: Double, qVitr: Double, pAtm: Double = 1.0) -> Double {
        return (nBal * vBal * pRob) / (qVitr * pAtm)
    }

    /// Рассчитать время работы у очага пожара (згідно з методичними рекомендаціями)
    func calculateWorkTime(minPressure: Int, minPressureNearFire: Int, deviceType: DeviceType, workMode: WorkMode) -> Int {
        // P_роб = P_поч.роб - P_вих
        let pStartWork = Double(minPressureNearFire)
        let pExit = Double(calculateExitPressureAir(pPr: Double(minPressure - minPressureNearFire), pRez: deviceType.reservePressure))
        let pRob = calculatePressureForWork(pStartWork: pStartWork, pExit: pExit)

        // Расчет времени по формуле з урахуванням режиму роботи
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let qVitr = workMode.airConsumption

        let time = OperationWorkController.calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: pRob, qVitr: qVitr)
        return Int(time)
    }

    /// Рассчитать давление на пути к очагу (згідно з методичними рекомендаціями)
    func calculatePressureOnPath(minPressure: Int, minPressureNearFire: Int, deviceType: DeviceType, workMode: WorkMode) -> Int {
        let pIncl = Double(minPressure)
        let pStartWork = Double(minPressureNearFire)
        let pressureOnPath = calculatePressureStraight(pIncl: pIncl, pStartWork: pStartWork)

        return Int(pressureOnPath)
    }

    /// Рассчитать минуты до выхода (згідно з методичними рекомендаціями)
    func calculateExitMinutes(pressureGo: Int, workTime: Int, deviceType: DeviceType, workMode: WorkMode) -> Int {
        // Використовуємо розрахунок часу роботи з урахуванням режиму
        return workTime
    }

    // MARK: - New Calculation Methods (from Gemini)

    /// Розрахунок тиску виходу
    func calculateExitPressureAir(pPr: Double, pRez: Double = 50.0) -> Double {
        return pPr + pRez
    }

    /// Тиск витрачений на прямування (P_пр)
    func calculatePressureStraight(pIncl: Double, pStartWork: Double) -> Double {
        return pIncl - pStartWork
    }

    /// Робочий тиск доступний для роботи в НДС (P_роб)
    func calculatePressureForWork(pStartWork: Double, pExit: Double) -> Double {
        return pStartWork - pExit
    }

    /// Розрахунок реального расходу повітря на основі часу пошуку очага
    func calculateActualAirConsumption(initialPressure: Int, currentPressure: Int, searchTimeMinutes: Int, deviceType: DeviceType) -> Double {
        // Розрахунок витраченого тиску на пошук
        let pressureSpent = Double(initialPressure - currentPressure)

        // Якщо тиск не змінився, повертаємо стандартний расход
        if pressureSpent <= 0 {
            return workData.operationData.deviceType.airConsumption
        }

        // Якщо час пошуку = 0, але тиск змінився, встановлюємо мінімальний час 0.5 хвилин
        let effectiveSearchTime = max(Double(searchTimeMinutes), 0.5)

        // Розрахунок об'єму повітря, витраченого на пошук
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let volumeSpent = (nBal * vBal * pressureSpent) / 1.0 // P_atm = 1 бар

        // Розрахунок реального расходу (л/хв)
        let actualConsumption = volumeSpent / effectiveSearchTime

        // Обмежуємо мінімальний і максимальний расход згідно з характеристиками апарата
        let deviceConsumption = workData.operationData.deviceType.airConsumption
        let minConsumption = deviceConsumption * 0.5
        let maxConsumption = deviceConsumption * 2.0

        // Якщо розрахунковий расход перевищує максимум, видаємо попередження
        if actualConsumption > maxConsumption {
            consumptionWarningMessage = "⚠️ УВАГА: Розрахунковий расход повітря (\(Int(actualConsumption)) л/мин) перевищує максимальні можливості апарата (\(Int(maxConsumption)) л/мин)!\n\nМожлива помилка в даних або надто інтенсивна робота ланки."
            showingConsumptionWarning = true
            print("⚠️ ПОПЕРЕДЖЕННЯ: Розрахунковий расход повітря (\(Int(actualConsumption)) л/мин) перевищує максимальні можливості апарата!")
        }

        return max(minConsumption, min(maxConsumption, actualConsumption))
    }

    /// Розрахунок часу роботи у осередку з урахуванням реального расходу
    func calculateWorkTimeWithActualConsumption(minPressure: Int, deviceType: DeviceType, actualAirConsumption: Double) -> Int {
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let pRob = Double(minPressure) - deviceType.reservePressure
        let qVitr = actualAirConsumption
        let pAtm = 1.0

        let time = OperationWorkController.calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: pRob, qVitr: qVitr, pAtm: pAtm)
        return Int(time)
    }

    /// Розрахунок часу виходу з урахуванням реального расходу повітря
    func calculateExitTimeWithActualConsumption(initialPressure: Int, currentPressure: Int, searchTimeMinutes: Int, deviceType: DeviceType, actualAirConsumption: Double) -> Int {
        // Розрахунок тиску, необхідного для виходу (від резервного)
        let exitPressure = Double(currentPressure) - deviceType.reservePressure

        if exitPressure <= 0 {
            return 0 // Неможливо вийти
        }

        // Розрахунок часу на вихід з урахуванням реального расходу
        // Це час, за який витрачається повітря від поточного тиску до резервного
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let pAtm = 1.0

        let exitTime = OperationWorkController.calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: exitPressure, qVitr: actualAirConsumption, pAtm: pAtm)

        return Int(exitTime)
    }

    /// Критичний тиск (P_кр) - згідно з методичними рекомендаціями
    static func calculateCriticalPressure(pIncl: Double, pRez: Double = 50.0) -> Double {
        return (pIncl - pRez) / 2
    }

    /// Розрахунок тиску початку виходу (P_вых = P_пр + P_рез)
    func calculateExitStartPressure(minPressure: Int, pressureAtWork: Int, deviceType: DeviceType) -> Int {
        let pressureAtEntry = Double(minPressure)
        let pressureAtWorkDouble = Double(pressureAtWork)
        let reserve = Double(deviceType.reservePressure)

        let pressureSpentThere = pressureAtEntry - pressureAtWorkDouble  // P_пр
        let exitPressure = pressureSpentThere + reserve                 // P_вых

        return Int(exitPressure)
    }

    /// Розрахунок часу роботи з урахуванням критичного тиску
    func calculateWorkTimeWithCriticalPressure(minPressure: Int, deviceType: DeviceType, workMode: WorkMode) -> Int {
        let criticalPressure = OperationWorkController.calculateCriticalPressure(pIncl: Double(minPressure), pRez: deviceType.reservePressure)
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let qVitr = workMode.airConsumption
        let pAtm = 1.0

        // Розрахунок часу до критичного тиску
        let time = OperationWorkController.calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: criticalPressure, qVitr: qVitr, pAtm: pAtm)
        return Int(time)
    }

    /// Необхідний тиск для застосування капюшона (згідно з методичними рекомендаціями)
    static func calculateHoodPressure(pIncl: Double, pStartWork: Double, isVictimHelping: Bool, pRez: Double = 50.0) -> Double {
        let diff = pIncl - pStartWork
        if isVictimHelping {
            // Для рятування постраждалого: 3 * (P_поч - P_поч.роб) + P_рез
            return 3 * diff + pRez
        } else {
            // Для власного рятування: 2 * (P_поч - P_поч.роб) + P_рез
            return 2 * diff + pRez
        }
    }

    /// Розрахунок часу евакуації з постраждалим
    static func calculateEvacuationTimeWithVictim(minPressure: Int, deviceType: DeviceType, workMode: WorkMode) -> Int {
        let criticalPressure = calculateCriticalPressure(pIncl: Double(minPressure), pRez: deviceType.reservePressure)
        let hoodPressure = calculateHoodPressure(pIncl: Double(minPressure), pStartWork: criticalPressure, isVictimHelping: true, pRez: deviceType.reservePressure)

        if Double(minPressure) >= hoodPressure {
            // Можна евакуювати з постраждалим
            let nBal = Double(deviceType.cylinderCount)
            let vBal = deviceType.cylinderVolume
            let qVitr = workMode.airConsumption * 1.5  // підвищений расход при евакуації
            let pAtm = 1.0

            let remainingPressure = Double(minPressure) - hoodPressure
            let time = calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: remainingPressure, qVitr: qVitr, pAtm: pAtm)
            return Int(time)
        } else {
            // Недостатньо тиску для евакуації з постраждалим
            return 0
        }
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


    // MARK: - Background Handling

    func setupScenePhaseObserver() {
        // Этот метод будет вызываться из SwiftUI view с @Environment(\.scenePhase)
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        // Делегируем обработку фона ActiveOperationsManager
        appState?.activeOperationsManager.handleScenePhaseChange(phase)
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

