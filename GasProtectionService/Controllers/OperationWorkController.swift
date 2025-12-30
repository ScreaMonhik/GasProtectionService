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

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    init(operationData: OperationData) {
        self.workData = OperationWorkData(operationData: operationData)
        super.init()
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
        if workData.exitTimer > 0 {
            workData.exitTimer -= 1
        }
        if workData.remainingTimer > 0 {
            workData.remainingTimer -= 1
        }
        if workData.communicationTimer > 0 {
            workData.communicationTimer -= 1
        }
    }

    func findFireSource() {
        workData.hasFoundFireSource = true
        workData.fireSourceFoundTime = Date()
    }

    func startWorkInDangerZone() {
        workData.isWorkingInDangerZone = true
        workData.dangerZoneStartTime = Date()
    }

    func startExitFromDangerZone() {
        workData.isExitingDangerZone = true
        workData.dangerZoneExitTime = Date()
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
