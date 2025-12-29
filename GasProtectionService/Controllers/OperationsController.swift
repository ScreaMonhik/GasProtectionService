//
//  OperationsController.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 26.12.2025.
//

import Foundation
import Combine

class OperationsController: ObservableObject {
    private let operationsKey = "operations_data"

    @Published var operations: [OperationData] = [] {
        didSet {
            saveOperations()
        }
    }

    @Published var isCreatingOperation = false

    init() {
        loadOperations()
    }

    func addOperation(_ operation: OperationData) {
        operations.append(operation)
    }

    func deleteOperation(_ operation: OperationData) {
        operations.removeAll { $0.id == operation.id }
    }

    private func saveOperations() {
        do {
            let data = try JSONEncoder().encode(operations)
            UserDefaults.standard.set(data, forKey: operationsKey)
        } catch {
            print("Error saving operations: \(error)")
        }
    }

    private func loadOperations() {
        guard let data = UserDefaults.standard.data(forKey: operationsKey) else { return }
        do {
            operations = try JSONDecoder().decode([OperationData].self, from: data)
        } catch {
            print("Error loading operations: \(error)")
        }
    }
}

// MARK: - Operation Creation Controller
class OperationCreationController: ObservableObject {
    @Published var newCommand = OperationData()
    @Published var showingOperationTypePicker = false
    @Published var showingDevicePicker = false
    @Published var showingRolePicker = false
    @Published var rolePickerMemberIndex: Int?
    @Published var isEditingExisting = false

    init(availableCommand: CheckCommand? = nil) {
        if let command = availableCommand {
            isEditingExisting = true

            // Пытаемся загрузить сохраненные данные операции
            var loadedMembers = command.teamMembers.map { teamMember in
                OperationMember(
                    role: .firefighter, // По умолчанию
                    fullName: teamMember.fullName,
                    pressure: teamMember.pressure,
                    isActive: true
                )
            }

            // Если есть сохраненные данные операции, используем роли из них
            if let workData = OperationWorkController.loadWorkDataForCommand(command.id) {
                loadedMembers = workData.operationData.members
            }

            // Конвертируем CheckCommand в OperationData
            newCommand = OperationData(
                operationType: .fire, // По умолчанию
                deviceType: command.deviceType,
                members: loadedMembers
            )
        }
    }

    // MARK: - Public Methods

    func addMember() {
        newCommand.members.append(OperationMember())
    }

    func removeMember() {
        if let lastActiveIndex = newCommand.members.lastIndex(where: { $0.isActive }) {
            newCommand.members.remove(at: lastActiveIndex)
        }
    }

    func removeMemberAt(_ index: Int) {
        if index < newCommand.members.count {
            newCommand.members.remove(at: index)
        }
    }

    func canRemoveMember() -> Bool {
        let activeMembers = newCommand.members.filter { $0.isActive }
        return activeMembers.count > 2
    }

    func canRemoveMemberAt(_ index: Int) -> Bool {
        let activeMembers = newCommand.members.filter { $0.isActive }
        return activeMembers.count > 2
    }

    func toggleMemberActive(_ index: Int) {
        newCommand.members[index].isActive.toggle()
    }

    func showRolePicker(for memberIndex: Int) {
        rolePickerMemberIndex = memberIndex
        showingRolePicker = true
    }

    func selectRole(_ role: TeamMemberRole) {
        if let index = rolePickerMemberIndex {
            newCommand.members[index].role = role
        }
        showingRolePicker = false
        rolePickerMemberIndex = nil
    }

    func setEntryTime(_ time: Date) {
        newCommand.settings.entryTime = time
    }

    func isValidOperation() -> Bool {
        let activeMembers = newCommand.members.filter { $0.isActive }
        return activeMembers.count >= 2 &&
               activeMembers.allSatisfy { !$0.fullName.isEmpty }
    }
}
