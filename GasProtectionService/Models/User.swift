//
//  User.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import Foundation

struct User {
    let id: Int
    let email: String
    let name: String
    let role: UserRole

    enum UserRole {
        case defaultUser
        case administrator
    }

    // Mock user for development
    static let mockUser = User(
        id: 1,
        email: "user@gdzs.ua",
        name: "Олександр Семененко",
        role: .defaultUser
    )
}
