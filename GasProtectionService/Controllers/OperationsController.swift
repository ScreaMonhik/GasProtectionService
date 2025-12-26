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
    @Published var operation = OperationData()
    @Published var showingOperationTypePicker = false
    @Published var showingDevicePicker = false
    @Published var showingRolePicker = false
    @Published var rolePickerMemberIndex: Int?

    // MARK: - Public Methods

    func addMember() {
        operation.members.append(OperationMember())
    }

    func removeMember() {
        if operation.members.count > 1 {
            operation.members.removeLast()
        }
    }

    func canRemoveMember() -> Bool {
        return operation.members.count > 1
    }

    func toggleMemberActive(_ index: Int) {
        operation.members[index].isActive.toggle()
    }

    func showRolePicker(for memberIndex: Int) {
        rolePickerMemberIndex = memberIndex
        showingRolePicker = true
    }

    func selectRole(_ role: TeamMemberRole) {
        if let index = rolePickerMemberIndex {
            operation.members[index].role = role
        }
        showingRolePicker = false
        rolePickerMemberIndex = nil
    }

    func setEntryTime(_ time: Date) {
        operation.settings.entryTime = time
    }

    func isValidOperation() -> Bool {
        !operation.members.isEmpty &&
        operation.members.contains { !$0.fullName.isEmpty }
    }
}
