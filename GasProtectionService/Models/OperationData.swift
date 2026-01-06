//
//  OperationData.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 06.01.2026.
//

import Foundation

// MARK: - Operation Settings
struct OperationSettings: Codable {
    var workBelowLimit: Bool = false
    var entryTime: Date?
}

// MARK: - Operation Data
struct OperationData: Codable, Identifiable {
    var id: UUID
    let createdDate: Date
    var commandName: String? // Название команды/ланки
    var operationType: OperationType
    var deviceType: DeviceType
    var members: [OperationMember]
    var settings: OperationSettings

    init(operationType: OperationType = .fire,
         deviceType: DeviceType = .dragerPSS3000,
         members: [OperationMember] = [],
         commandName: String? = nil) {
        self.id = UUID()
        self.createdDate = Date()
        self.commandName = commandName
        self.operationType = operationType
        self.deviceType = deviceType
        self.members = members.isEmpty ? [OperationMember(), OperationMember()] : members
        self.settings = OperationSettings()
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: createdDate)
    }

    var formattedEntryTime: String {
        guard let time = settings.entryTime else { return "Не обрано" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}
