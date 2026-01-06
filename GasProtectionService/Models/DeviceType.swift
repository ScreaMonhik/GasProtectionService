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



    var cylinderVolume: Double {
        switch self {
        case .dragerPSS3000, .msa:
            return 6.0  // літри
        case .dragerPSS4000:
            return 7.0  // літри
        case .asp2:
            return 4.5  // літри
        }
    }

    var cylinderCount: Int {
        switch self {
        case .dragerPSS3000, .dragerPSS4000, .msa:
            return 1  // Drager аппараты имеют 1 баллон
        case .asp2:
            return 2  // АСП-2 аппараты имеют 2 баллона
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
