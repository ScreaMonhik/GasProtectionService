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

// MARK: - Work Mode
enum WorkMode: Int, Codable {
    case average = 1    // среднее навантаження
    case heavy = 2      // важкое навантаження

    var airConsumption: Double {
        switch self {
        case .average: return 40.0  // л/мин
        case .heavy: return 80.0    // л/мин
        }
    }
}

// MARK: - Operation Work Data
struct OperationWorkData: Codable, Identifiable {
    var id: UUID
    let createdDate: Date
    var operationData: OperationData

    // Work parameters
    var workMode: WorkMode = .average
    var minPressure: Int = 300  // минимальный тиск в ланці
    var initialMinPressure: Int = 300  // начальный минимальный тиск при входе в НДС
    var protectionTime: Int = 0  // время защитной работы аппарата (статичное)

    // Timers (активные, уменьшаются со временем)
    var exitTimer: TimeInterval = 0 // Initially 0, calculated later
    var remainingTimer: TimeInterval = 0 // Initially 0, calculated later
//    var communicationTimer: TimeInterval = 10 * 60 // 10 minutes
    var communicationTimer: TimeInterval = 15 // 15 seconds (for Debug purposes)

    // States
    var hasFoundFireSource: Bool = false
    var isWorkingInDangerZone: Bool = false
    var isExitingDangerZone: Bool = false

    // Times
    var fireSourceFoundTime: Date?
    var dangerZoneStartTime: Date?
    var dangerZoneExitTime: Date?

    // Data
    var lowestPressure: String = ""
    var exitStartPressure: String = ""
    var minimumExitPressure: String = ""

    // Calculated data (статичные расчеты)
    var pressureOnPath: Int = 0  // тиск використаний на прямування
    var workTime: Int = 0        // время работы у очага
    var searchTime: Int = 0      // время поиска очага пожара в минутах
    var criticalPressure: Int = 0 // критичний тиск (згідно з методичними рекомендаціями)
    var hoodPressure: Int = 0    // тиск для застосування капюшона
    var evacuationTimeWithVictim: Int = 0 // час евакуації з постраждалим

    // Address
    var workAddress: String = ""

    init(operationData: OperationData) {
        self.id = UUID()
        self.createdDate = Date()
        self.operationData = operationData
    }

    init(operationData: OperationData, protectionTime: Int, minPressure: Int, remainingTimer: TimeInterval, exitTimer: TimeInterval) {
        self.id = UUID()
        self.createdDate = Date()
        self.operationData = operationData
        self.protectionTime = protectionTime
        self.minPressure = minPressure
        self.remainingTimer = remainingTimer
        self.exitTimer = exitTimer
    }

    var formattedFireSourceFoundTime: String {
        guard let time = fireSourceFoundTime else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    var formattedDangerZoneStartTime: String {
        guard let time = dangerZoneStartTime else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    var formattedDangerZoneExitTime: String {
        guard let time = dangerZoneExitTime else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    var expectedExitTime: String {
        guard let entryTime = operationData.settings.entryTime else { return "--:--" }
        // Добавляем время оставшейся работы (remainingTimer в секундах)
        let exitTime = entryTime.addingTimeInterval(TimeInterval(remainingTimer))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let result = formatter.string(from: exitTime)
        // print("📅 expectedExitTime: remainingTimer=\(remainingTimer), result=\(result)")
        return result
    }

    var consumptionRate: String {
        return "20,0 л/хв"
    }

    var formattedPressureOnPath: String {
        return "\(pressureOnPath) бар"
    }

    var formattedWorkTime: String {
        let minutes = workTime
        return "\(minutes) хв"
    }

    var formattedProtectionTime: String {
        return "\(protectionTime) хв"
    }

    var formattedExitTime: String {
        guard let exitTime = dangerZoneExitTime else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: exitTime)
    }

    var calculatedExitStartPressure: String {
        // Рассчитывает давление, при котором нужно начинать выход (P_вых)
        // P_вых = P_пр + P_рез, где P_пр = P_вкл - P_поч.роб
        guard let lowestPressureValue = Int(lowestPressure), !lowestPressure.isEmpty else {
            return "Введіть тиск у вогню"
        }

        let pressureAtEntry = Double(minPressure)      // P_вкл - минимальный тиск в ланці
        let pressureAtWork = Double(lowestPressureValue) // P_поч.роб - давление у огня
        let reserve = Double(operationData.deviceType.reservePressure) // P_рез - резерв аппарата

        let pressureSpentThere = pressureAtEntry - pressureAtWork  // P_пр
        let exitPressure = pressureSpentThere + reserve           // P_вых

        return "\(Int(exitPressure)) бар"
    }

    private func calculateExitPressureAir(pressureAtEntry: Double, pressureAtWork: Double, reserve: Double = 50.0) -> Double {
        // 1. Считаем, сколько потратили на дорогу ТУДА (P_пр)
        // P_пр = P_вкл - P_поч.роб
        let pressureSpentThere = pressureAtEntry - pressureAtWork

        // 2. Считаем давление выхода
        // P_вых = P_пр + P_рез
        return pressureSpentThere + reserve
    }
}
