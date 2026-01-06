//
//  OperationMember.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 06.01.2026.
//

import Foundation

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
            return "flame.fill" 
        case .squadLeader:
            return "star.circle.fill"
        case .safetyPost:
            return "shield.checkerboard"
        }
    }

    var iconColor: String {
        switch self {
        case .firefighter:
            return "systemOrange"
        case .squadLeader:
            return "systemRed"
        case .safetyPost:
            return "systemGreen"
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
