//
//  GasCalculator.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 06.01.2026.
//

import Foundation

class GasCalculator {
    
    // MARK: - Data Helpers
    
    /// Отримати мінімальний тиск в команді
    static func getMinPressureInTeam(from members: [OperationMember]) -> Int {
        let activeMembers = members.filter { $0.isActive }
        let pressures = activeMembers.compactMap { Int($0.pressure) }
        return pressures.min() ?? 0
    }

    // MARK: - Work Calculations
    
    /// Рассчитать время защитной работы аппарата (згідно з методичними рекомендаціями)
    static func calculateProtectionTime(minPressure: Int, deviceType: DeviceType) -> Double {
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let pRob = Double(minPressure) - deviceType.reservePressure
        let qVitr = deviceType.airConsumption
        let pAtm = 1.0

        // Формула: (N_бал * V_бал * P_роб) / (Q_витр * K_сж)
        let numerator = nBal * vBal * pRob
        let denominator = qVitr * pAtm
        let time = numerator / denominator

        return time
    }
    
    /// Расчет времени работы (универсальная формула)
    static func calculateWorkTimeAir(nBal: Double, vBal: Double, pRob: Double, qVitr: Double, pAtm: Double = 1.0) -> Double {
        return (nBal * vBal * pRob) / (qVitr * pAtm)
    }
    
    /// Критичний тиск (P_кр) - згідно з методичними рекомендаціями
    static func calculateCriticalPressure(pIncl: Double, pRez: Double = 50.0) -> Double {
        return (pIncl - pRez) / 2
    }
    
    /// Необхідний тиск для застосування капюшона (згідно з методичними рекомендаціями)
    static func calculateHoodPressure(pIncl: Double, pStartWork: Double, isVictimHelping: Bool, pRez: Double = 50.0) -> Double {
        let diff = pIncl - pStartWork
        if isVictimHelping {
            // Для рятування постраждалого: 3 * (P_поч - P_поч.роб) + P_рез
            return 3 * diff + pRez
        } else {
            // Для власного рятування: 2 * (P_поч - P_поч.роб) + P_рез
            return 2 * diff + pRez
        }
    }
    
    /// Розрахунок часу евакуації з постраждалим
    static func calculateEvacuationTimeWithVictim(minPressure: Int, deviceType: DeviceType, workMode: WorkMode) -> Int {
        let criticalPressure = calculateCriticalPressure(pIncl: Double(minPressure), pRez: deviceType.reservePressure)
        let hoodPressure = calculateHoodPressure(pIncl: Double(minPressure), pStartWork: criticalPressure, isVictimHelping: true, pRez: deviceType.reservePressure)
        
        if Double(minPressure) >= hoodPressure {
            // Можна евакуювати з постраждалим
            let nBal = Double(deviceType.cylinderCount)
            let vBal = deviceType.cylinderVolume
            let qVitr = workMode.airConsumption * 1.5  // підвищений расход при евакуації
            let pAtm = 1.0
            
            let remainingPressure = Double(minPressure) - hoodPressure
            let time = calculateWorkTimeAir(nBal: nBal, vBal: vBal, pRob: remainingPressure, qVitr: qVitr, pAtm: pAtm)
            return Int(time)
        } else {
            // Недостатньо тиску для евакуації з постраждалим
            return 0
        }
    }
    
    /// Розрахунок тиску початку виходу (P_вых = P_пр + P_рез)
    static func calculateExitStartPressure(minPressure: Int, pressureAtWork: Int, deviceType: DeviceType) -> Int {
        let pressureAtEntry = Double(minPressure)
        let pressureAtWorkDouble = Double(pressureAtWork)
        let reserve = Double(deviceType.reservePressure)
        
        let pressureSpentThere = pressureAtEntry - pressureAtWorkDouble  // P_пр
        let exitPressure = pressureSpentThere + reserve                 // P_вых
        
        return Int(exitPressure)
    }
    
    /// Розрахунок реального расходу повітря на основі часу пошуку очага
    static func calculateActualAirConsumption(initialPressure: Int, currentPressure: Int, searchTimeMinutes: Double, deviceType: DeviceType) -> Double {
        // Розрахунок витраченого тиску на пошук
        let pressureSpent = Double(initialPressure - currentPressure)
        
        // Якщо тиск не змінився, повертаємо стандартний расход
        if pressureSpent <= 0 {
            return deviceType.airConsumption
        }
        
        // Якщо час пошуку = 0, але тиск змінився, встановлюємо мінімальний час 0.5 хвилин
        let effectiveSearchTime = max(searchTimeMinutes, 0.5)
        
        // Розрахунок об'єму повітря, витраченого на пошук
        let nBal = Double(deviceType.cylinderCount)
        let vBal = deviceType.cylinderVolume
        let volumeSpent = (nBal * vBal * pressureSpent) / 1.0 // P_atm = 1 бар
        
        // Розрахунок реального расходу (л/хв)
        let actualConsumption = volumeSpent / effectiveSearchTime
        
        // Обмежуємо мінімальний расход, але не максимальний
        // щоб можна було виявити надмірне споживання і показати попередження
        let minConsumption = deviceType.airConsumption * 0.5
        
        return max(minConsumption, actualConsumption)
    }
}
