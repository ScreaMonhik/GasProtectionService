//
//  DeviceType.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 06.01.2026.
//

import Foundation

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

    var cylinderVolume: Double {
        switch self {
        case .dragerPSS3000, .dragerPSS4000:
            return 6.8  // литры
        case .asp2:
            return 7.0  // литры
        case .msa:
            return 6.0  // литры
        }
    }

    var cylinderCount: Int {
        switch self {
        case .dragerPSS3000, .dragerPSS4000:
            return 1  // Drager аппараты имеют 1 баллон
        case .asp2, .msa:
            return 1  // остальные имеют 1 баллон
        }
    }

    var reservePressure: Double {
        switch self {
        case .dragerPSS3000, .dragerPSS4000, .msa:
            return 50.0  // бар
        case .asp2:
            return 30.0  // бар
        }
    }

    var airConsumption: Double {
        switch self {
        case .dragerPSS3000, .dragerPSS4000:
            return 40.0  // л/мин для Drager
        case .asp2:
            return 54.0  // л/мин для АСП-2
        case .msa:
            return 45.0  // л/мин для MSA
        }
    }
}
