//
//  AuthenticationCredentials.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import Foundation

struct AuthenticationCredentials {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
}

// Type alias for backward compatibility
typealias LoginCredentials = AuthenticationCredentials
