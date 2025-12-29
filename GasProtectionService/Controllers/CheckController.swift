//
//  CheckController.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import Foundation
import Combine

class CheckController: ObservableObject {
    private let commandsKey = "check_commands"

    @Published var commands: [CheckCommand] = [] {
        didSet {
            saveCommands()
        }
    }

    // Фильтрованные списки команд
    var journalCommands: [CheckCommand] {
        commands.filter { $0.commandType == .operation }
    }

    var teamCommands: [CheckCommand] {
        commands.filter { $0.commandType == .command }
    }

    @Published var isCreatingCommand = false

    init() {
        loadCommands()
    }

    func addCommand(_ command: CheckCommand) {
        commands.insert(command, at: 0)
    }

    func updateCommand(_ command: CheckCommand) {
        if let index = commands.firstIndex(where: { $0.id == command.id }) {
            commands[index] = command
        } else {
            addCommand(command)
        }
    }

    func deleteCommand(_ command: CheckCommand) {
        commands.removeAll { $0.id == command.id }
    }

    private func saveCommands() {
        do {
            let data = try JSONEncoder().encode(commands)
            UserDefaults.standard.set(data, forKey: commandsKey)
        } catch {
            print("Error saving commands: \(error)")
        }
    }

    private func loadCommands() {
        guard let data = UserDefaults.standard.data(forKey: commandsKey) else { return }
        do {
            commands = try JSONDecoder().decode([CheckCommand].self, from: data)
        } catch {
            print("Error loading commands: \(error)")
        }
    }
}

// MARK: - Command Creation Controller
class CommandCreationController: ObservableObject {
    @Published var command: CheckCommand
    @Published var showingDevicePicker = false
    @Published var showingRescueAlert = false
    @Published var alertMemberIndex: Int?

    init(command: CheckCommand? = nil) {
        self.command = command ?? CheckCommand(teamMembers: [TeamMember(), TeamMember()])
    }

    // MARK: - Public Methods

    func addTeamMember() {
        command.teamMembers.append(TeamMember())
    }

    func removeTeamMember() {
        if command.teamMembers.count > 2 {
            command.teamMembers.removeLast()
        }
    }

    func removeTeamMember(at index: Int) {
        if command.teamMembers.count > 2 && index < command.teamMembers.count {
            command.teamMembers.remove(at: index)
        }
    }

    func canRemoveMember() -> Bool {
        return command.teamMembers.count > 2
    }

    func canRemoveMember(at index: Int) -> Bool {
        return command.teamMembers.count > 2
    }

    func toggleRescueDevice(for memberIndex: Int) {
        alertMemberIndex = memberIndex
        showingRescueAlert = true
    }

    func setRescueDevice(hasDevice: Bool) {
        if let index = alertMemberIndex {
            command.teamMembers[index].hasRescueDevice = hasDevice
        }
        showingRescueAlert = false
        alertMemberIndex = nil
    }

    func isValidCommand() -> Bool {
        !command.commandName.isEmpty &&
        command.teamMembers.count >= 2 &&
        command.teamMembers.allSatisfy { !$0.fullName.isEmpty }
    }

    func reset() {
        command = CheckCommand()
        showingDevicePicker = false
        showingRescueAlert = false
        alertMemberIndex = nil
    }
}
