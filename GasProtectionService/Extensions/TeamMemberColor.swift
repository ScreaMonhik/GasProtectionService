//
//  TeamMemberColor.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import SwiftUI

extension TeamMemberRole {
    
    // Мы создаем новое свойство 'color', так как 'iconColor' уже занято строкой
    var color: Color {
        switch self.iconColor {
        case "systemOrange":
            return .orange
        case "systemRed":
            return .red
        case "systemGreen":
            return .green
        default:
            return .gray // Цвет на случай ошибки
        }
    }
}
