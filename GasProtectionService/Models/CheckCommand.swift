//
//  CheckCommand.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import Foundation

enum CommandType: String, Codable {
    case command // для данных о ланке
    case operation // для данных об операции
}

struct CheckCommand: Codable, Identifiable {
    let id: UUID
    var commandName: String
    var deviceType: DeviceType
    var teamMembers: [TeamMember]
    let createdDate: Date
    var commandType: CommandType
    var workAddress: String

    init(commandName: String = "", deviceType: DeviceType = .dragerPSS3000, teamMembers: [TeamMember] = [], commandType: CommandType = .command, workAddress: String = "") {
        self.id = UUID()
        self.commandName = commandName
        self.deviceType = deviceType
        self.teamMembers = teamMembers
        self.createdDate = Date()
        self.commandType = commandType
        self.workAddress = workAddress
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: createdDate)
    }
}

enum DeviceType: String, Codable, CaseIterable {
    case dragerPSS3000 = "Drager PSS3000"
    case dragerPSS4000 = "Drager PSS4000"
    case asp2 = "АСП-2"
    case msa = "MSA"

    var displayName: String {
        return self.rawValue
    }

    var protectionTimeMinutes: Int {
        switch self {
        case .dragerPSS3000:
            return 35
        case .dragerPSS4000:
            return 40
        case .asp2:
            return 37
        case .msa:
            return 39
        }
    }
}

struct TeamMember: Codable, Identifiable {
    let id: UUID
    var fullName: String
    var pressure: String
    var hasRescueDevice: Bool

    init(fullName: String = "", pressure: String = "", hasRescueDevice: Bool = false) {
        self.id = UUID()
        self.fullName = fullName
        self.pressure = pressure
        self.hasRescueDevice = hasRescueDevice
    }
}
