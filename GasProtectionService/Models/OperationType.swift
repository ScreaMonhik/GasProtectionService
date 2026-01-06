//
//  OperationType.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 06.01.2026.
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
