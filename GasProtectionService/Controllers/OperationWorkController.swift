//
//  OperationWorkController.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import Foundation
import Combine
import CoreLocation

class OperationWorkController: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var workData: OperationWorkData
    @Published var showingAddressAlert = false
    @Published var showingTeamInfo = false
    @Published var currentAddress = ""
    @Published var isLoadingLocation = false
    @Published var showingPressureAlert = false
    @Published var pressureAlertMessage = ""
    @Published var showingConsumptionWarning = false
    @Published var consumptionWarningMessage = ""

    // Callback для алертов вместо @Published
    var onValidationError: ((String) -> Void)?
    var alertAlreadyShown = false  // Internal access for View

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // MARK: - Work Calculation Constants (згідно з методичними рекомендаціями)
    private let reservDrager = 50  // резерв для Drager аппаратов (50-60 бар для сигнального пристрою)
    private let reservASV = 30     // резерв для ASP-2 аппарата

    init(operationData: OperationData) {
        var workData = OperationWorkData(operationData: operationData)

        self.workData = workData
        super.init()

        // Начальное давление будет установлено при начале работы в НДС
        var updatedWorkData = workData
        updatedWorkData.minPressure = getMinPressureInTeam()

        // Рассчитываем время защитной работы аппарата
        updatedWorkData.protectionTime = calculateProtectionTime(
            minPressure: updatedWorkData.minPressure,
            deviceType: operationData.deviceType
        )

        // Розраховуємо критичний тиск та інші параметри згідно з методичними рекомендаціями
        updatedWorkData.criticalPressure = Int(calculateCriticalPressure(
            pIncl: Double(updatedWorkData.minPressure),
            pRez: operationData.deviceType.reservePressure
        ))
        updatedWorkData.hoodPressure = Int(calculateHoodPressure(
            pIncl: Double(updatedWorkData.minPressure),
            pStartWork: Double(updatedWorkData.criticalPressure),
            isVictimHelping: false,
            pRez: operationData.deviceType.reservePressure
        ))
        updatedWorkData.evacuationTimeWithVictim = calculateEvacuationTimeWithVictim(
            minPressure: updatedWorkData.minPressure,
            deviceType: operationData.deviceType,
            workMode: updatedWorkData.workMode
        )

        // Устанавливаем таймеры на основе расчетов
        updatedWorkData.remainingTimer = TimeInterval(updatedWorkData.protectionTime * 60)
        updatedWorkData.exitTimer = TimeInterval(updatedWorkData.protectionTime / 2 * 60) // Таймер "если не найден очаг"

        workData = updatedWorkData

        self.workData = workData
        setupTimer()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    deinit {
        timer?.invalidate()
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimers()
        }
    }

    private func updateTimers() {
        var updatedWorkData = workData
        if updatedWorkData.exitTimer > 0 {
            updatedWorkData.exitTimer -= 1
        }
        if updatedWorkData.remainingTimer > 0 {
            updatedWorkData.remainingTimer -= 1
        }
        if updatedWorkData.communicationTimer > 0 {
            updatedWorkData.communicationTimer -= 1
        }
        workData = updatedWorkData
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
    }

    /// Получить минимальное давление среди активных членов ланки
    func getMinPressureInTeam() -> Int {
        let activeMembers = workData.operationData.members.filter { $0.isActive }
        return activeMembers.compactMap { Int($0.pressure) }.min() ?? 0
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
        // Защита от повторного выполнения, если алерт уже показан
        if alertAlreadyShown {
            return
        }

        let minPressureNearFire = Int(workData.lowestPressure) ?? 0

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
                updatedWorkData.workTime = Int(calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: pressureDifference, qVitr: actualAirConsumption, pAtm: pAtm))
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
                let remainingTimeMinutes = calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: remainingPressure, qVitr: actualAirConsumption, pAtm: 1.0)
                updatedWorkData.remainingTimer = TimeInterval(remainingTimeMinutes * 60)
            } else {
                updatedWorkData.remainingTimer = 0
            }

            // Устанавливаем время выхода: время начала работы у очага + время работы у очага
            // Когда давление достигнет "тиску початку виходу", нужно начинать выход
            let exitTime = Date()
            updatedWorkData.dangerZoneStartTime = exitTime
            updatedWorkData.dangerZoneExitTime = exitTime.addingTimeInterval(TimeInterval(updatedWorkData.workTime * 60))
        }
        workData = updatedWorkData
    }

    func startExitFromDangerZone() {
        var updatedWorkData = workData
        updatedWorkData.isExitingDangerZone = true
        workData = updatedWorkData
    }

    func getCurrentLocation() {
        isLoadingLocation = true

        // Check location authorization status
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            isLoadingLocation = false
            return
        case .denied, .restricted:
            currentAddress = "Доступ до геолокації заборонено"
            isLoadingLocation = false
            return
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            currentAddress = "Невідома помилка геолокації"
            isLoadingLocation = false
            return
        }

        // Start location updates
        locationManager.startUpdatingLocation()
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
    func calculateProtectionTime(minPressure: Int, deviceType: DeviceType) -> Int {
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let pRob = Double(minPressure) - deviceType.reservePressure
        let qVitr = workData.workMode.airConsumption  // використовуємо режим роботи
        let pAtm = 1.0

        let time = calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: pRob, qVitr: qVitr, pAtm: pAtm)
        return Int(time)
    }

    /// Расчет времени работы (новая формула из Gemini)
    func calculateWorkTimeAir(nBal: Double, vBal: Double, pRob: Double, qVitr: Double, pAtm: Double = 1.0) -> Double {
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

        let time = calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: pRob, qVitr: qVitr)
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
            return workData.workMode.airConsumption
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
        let minConsumption = workData.workMode.airConsumption * 0.5  // 20 л/мин
        let maxConsumption = workData.workMode.airConsumption * 2.0  // 80 л/мин (максимум для Drager PSS3000)

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

        let time = calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: pRob, qVitr: qVitr, pAtm: pAtm)
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

        let exitTime = calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: exitPressure, qVitr: actualAirConsumption, pAtm: pAtm)

        return Int(exitTime)
    }

    /// Критичний тиск (P_кр) - згідно з методичними рекомендаціями
    func calculateCriticalPressure(pIncl: Double, pRez: Double = 50.0) -> Double {
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
        let criticalPressure = calculateCriticalPressure(pIncl: Double(minPressure), pRez: deviceType.reservePressure)
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let qVitr = workMode.airConsumption
        let pAtm = 1.0

        // Розрахунок часу до критичного тиску
        let time = calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: criticalPressure, qVitr: qVitr, pAtm: pAtm)
        return Int(time)
    }

    /// Необхідний тиск для застосування капюшона (згідно з методичними рекомендаціями)
    func calculateHoodPressure(pIncl: Double, pStartWork: Double, isVictimHelping: Bool, pRez: Double = 50.0) -> Double {
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
    func calculateEvacuationTimeWithVictim(minPressure: Int, deviceType: DeviceType, workMode: WorkMode) -> Int {
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

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoadingLocation = false
            return
        }

        // Stop updating location after getting first result
        locationManager.stopUpdatingLocation()

        // Создаём локаль для украинского языка
        let ukrainianLocale = Locale(identifier: "uk_UA")
        
        // Reverse geocoding to get address
        geocoder.reverseGeocodeLocation(location, preferredLocale: ukrainianLocale) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoadingLocation = false

                if let error = error {
                    self?.currentAddress = "Помилка визначення адреси: \(error.localizedDescription)"
                    return
                }

                if let placemark = placemarks?.first {
                    // Format address in Ukrainian style
                    var addressComponents = [String]()

                    if let streetName = placemark.thoroughfare, let streetNumber = placemark.subThoroughfare {
                        addressComponents.append("вул. \(streetName), \(streetNumber)")
                    } else if let streetName = placemark.thoroughfare {
                        addressComponents.append("вул. \(streetName)")
                    }

                    if let city = placemark.locality {
                        addressComponents.append(city)
                    }

                    if addressComponents.isEmpty {
                        self?.currentAddress = "Адреса не знайдена"
                    } else {
                        self?.currentAddress = addressComponents.joined(separator: ", ")
                    }
                } else {
                    self?.currentAddress = "Адреса не знайдена"
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoadingLocation = false
            self.currentAddress = "Помилка геолокації: \(error.localizedDescription)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Authorization granted, can now get location
            isLoadingLocation = false
        }
    }
}

