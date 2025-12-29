//
//  OperationWorkController.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import Foundation
import Combine

class OperationWorkController: ObservableObject {
    @Published var workData: OperationWorkData
    @Published var showingAddressAlert = false
    @Published var showingTeamInfo = false
    @Published var currentAddress = ""

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(operationData: OperationData) {
        self.workData = OperationWorkData(operationData: operationData)
        setupTimer()
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
        // TODO: Implement location services
        currentAddress = "вул. Шевченка, 1, Київ" // Mock address for now
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
}
