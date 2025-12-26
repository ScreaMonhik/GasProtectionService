//
//  OperationsModels.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 26.12.2025.
//

import Foundation

// MARK: - Operation Types
enum OperationType: String, Codable, CaseIterable {
    case fire = "Пожежа"
    case accident = "Аварія"
    case training = "Заняття"
    case exercise = "Навчання"

    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Team Member Role
enum TeamMemberRole: String, Codable, CaseIterable {
    case firefighter = "Пожежний"
    case squadLeader = "Командир ланки"
    case safetyPost = "Пост безпеки"

    var displayName: String {
        return self.rawValue
    }

    var iconName: String {
        switch self {
        case .firefighter:
            return "person.fill"
        case .squadLeader:
            return "person.badge.shield.checkmark.fill"
        case .safetyPost:
            return "shield.checkerboard"
        }
    }

    var iconColor: String {
        switch self {
        case .firefighter:
            return "blue"
        case .squadLeader:
            return "red"
        case .safetyPost:
            return "green"
        }
    }
}

// MARK: - Operation Member
struct OperationMember: Codable, Identifiable {
    let id: UUID
    var role: TeamMemberRole
    var fullName: String
    var pressure: String
    var isActive: Bool

    init(role: TeamMemberRole = .firefighter, fullName: String = "", pressure: String = "", isActive: Bool = true) {
        self.id = UUID()
        self.role = role
        self.fullName = fullName
        self.pressure = pressure
        self.isActive = isActive
    }
}

// MARK: - Operation Settings
struct OperationSettings: Codable {
    var workBelowLimit: Bool = false
    var entryTime: Date?
}

// MARK: - Operation Data
struct OperationData: Codable, Identifiable {
    let id: UUID
    let createdDate: Date
    var operationType: OperationType
    var deviceType: DeviceType
    var members: [OperationMember]
    var settings: OperationSettings

    init(operationType: OperationType = .fire,
         deviceType: DeviceType = .dragerPSS3000,
         members: [OperationMember] = []) {
        self.id = UUID()
        self.createdDate = Date()
        self.operationType = operationType
        self.deviceType = deviceType
        self.members = members.isEmpty ? [OperationMember()] : members
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
