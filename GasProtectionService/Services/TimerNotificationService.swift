//
//  TimerNotificationService.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import Foundation
import UserNotifications
import AudioToolbox

/// Сервис для управления максимально громкими уведомлениями таймеров для экстренных ситуаций
class TimerNotificationService {

    // MARK: - Singleton

    static let shared = TimerNotificationService()

    // MARK: - Properties

    private var customAlertSoundID: SystemSoundID = 0
    private var customSoundLoaded = false

    private init() {
        setupNotificationCategories()
        loadCustomAlertSound()
    }

    // MARK: - Public Methods

    /// Проверяет статус разрешений на уведомления (не запрашивает)
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            // Если уже авторизовано, регистрируем категории
            if settings.authorizationStatus == .authorized {
                self.setupNotificationCategories()
                completion(true)
                return
            }

            // Запрашиваем базовые разрешения
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    completion(false)
                    return
                }

                self.setupNotificationCategories()

                // Проверяем финальный статус
                center.getNotificationSettings { finalSettings in
                    let authorized = finalSettings.authorizationStatus == .authorized
                    let hasSound = finalSettings.soundSetting == .enabled
                    let hasAlerts = finalSettings.alertSetting == .enabled

                    completion(authorized && hasSound && hasAlerts)
                }
            }
        }
    }

    /// Планирует уведомление для таймера выхода
    func scheduleExitTimerNotification(timeInterval: TimeInterval) {
        guard timeInterval > 0 else { return }
        scheduleTimerNotification(
            title: "🚨 ГДЗС: Час виходу!",
            body: "Терміново! Таймер виходу з НДС завершився. Необхідно негайно покинути небезпечну зону!",
            timeInterval: timeInterval,
            identifier: "exit_timer_notification"
        )
    }

    /// Планирует уведомление для оставшегося времени работы
    func scheduleRemainingTimerNotification(timeInterval: TimeInterval) {
        guard timeInterval > 0 else { return }
        scheduleTimerNotification(
            title: "🚨 ГДЗС: Кінець часу роботи!",
            body: "Терміново! Час роботи кисневого апарата завершився. Необхідно негайно вийти з небезпечної зони!",
            timeInterval: timeInterval,
            identifier: "remaining_timer_notification"
        )
    }

    /// Планирует уведомление для таймера связи
    func scheduleCommunicationTimerNotification(timeInterval: TimeInterval) {
        guard timeInterval > 0 else { return }
        scheduleTimerNotification(
            title: "📡 ГДЗС: Час зв'язку",
            body: "Необхідно зв'язатися з ланкою для звіту",
            timeInterval: timeInterval,
            identifier: "communication_timer_notification"
        )
    }

    /// Планирует все уведомления для активных таймеров
    func scheduleAllTimerNotifications(exitTime: TimeInterval, remainingTime: TimeInterval, communicationTime: TimeInterval) {
        // Проверяем, есть ли хоть одно уведомление для планирования
        let hasValidTimers = exitTime > 0 || remainingTime > 0 || communicationTime > 0
        guard hasValidTimers else {
            return
        }

        checkAuthorizationStatus { [weak self] authorized in
            guard authorized, let self = self else {
                return
            }

            DispatchQueue.main.async {
                self.scheduleExitTimerNotification(timeInterval: exitTime)
                self.scheduleRemainingTimerNotification(timeInterval: remainingTime)
                self.scheduleCommunicationTimerNotification(timeInterval: communicationTime)
            }
        }
    }

    /// Отменяет все запланированные уведомления таймеров
    func cancelAllTimerNotifications() {
        let identifiers = [
            "exit_timer_notification",
            "remaining_timer_notification",
            "communication_timer_notification"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Проигрывает кастомный звук тревоги или системный
    func playCustomAlertSound() {
        if customSoundLoaded && customAlertSoundID != 0 {
            AudioServicesPlaySystemSound(customAlertSoundID)
        } else {
            // Fallback to system sounds
            AudioServicesPlaySystemSound(1304)
            AudioServicesPlaySystemSound(1110)
        }
    }

    /// Проигрывает локальный звуковой сигнал оповещения максимальной громкости
    func playAlertSound() {
        // Проигрываем серию максимально громких СЕРЬЕЗНЫХ звуков тревоги
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        // Используем кастомный звук если загружен, иначе системные
        if customSoundLoaded {
            playCustomAlertSound()
        } else {
            AudioServicesPlaySystemSound(1304) // Основной тревожный звук
            AudioServicesPlaySystemSound(1100) // Дополнительный серьезный звук
        }

        // Повторяем через короткие интервалы для создания тревожного эффекта
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if self.customSoundLoaded {
                self.playCustomAlertSound()
            } else {
                AudioServicesPlaySystemSound(1304)
                AudioServicesPlaySystemSound(1108) // Более тревожный звук
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if self.customSoundLoaded {
                self.playCustomAlertSound()
            } else {
                AudioServicesPlaySystemSound(1304)
                AudioServicesPlaySystemSound(1110) // Максимально тревожный звук
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if self.customSoundLoaded {
                self.playCustomAlertSound()
            } else {
                AudioServicesPlaySystemSound(1304)
                AudioServicesPlaySystemSound(1108)
            }
        }

        // Финальная серия для максимального внимания
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if self.customSoundLoaded {
                self.playCustomAlertSound()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.playCustomAlertSound() // Двойной для усиления
                }
            } else {
                AudioServicesPlaySystemSound(1304)
                AudioServicesPlaySystemSound(1110) // Максимально тревожный финальный звук
                AudioServicesPlaySystemSound(1110) // Двойной для усиления
            }
        }
    }

    // MARK: - Private Methods

    private func loadCustomAlertSound() {
        // Пытаемся загрузить кастомный звук тревоги для уведомлений
        // Сначала пробуем emergency_alert.wav в корне Bundle (для уведомлений), затем в Sounds/
        var soundURL: URL?

        // Для уведомлений файл должен быть в корне Bundle
        if let url = Bundle.main.url(forResource: "emergency_alert", withExtension: "wav") {
            soundURL = url
            print("✅ Custom emergency alert sound found in bundle root: \(url.lastPathComponent)")
        } else if let url = Bundle.main.url(forResource: "emergency_alert", withExtension: "wav", subdirectory: "Sounds") {
            soundURL = url
            print("⚠️ Custom emergency alert sound found in Sounds/ subdirectory: \(url.lastPathComponent)")
        }

        if let url = soundURL {
            let status = AudioServicesCreateSystemSoundID(url as CFURL, &customAlertSoundID)
            if status == kAudioServicesNoError {
                customSoundLoaded = true
                print("✅ Custom emergency alert sound loaded successfully")
                print("🎵 Background notifications will now use this custom sound!")
            } else {
                customSoundLoaded = false
                print("❌ Failed to load custom sound, status: \(status)")
            }
        } else {
            customSoundLoaded = false
            print("⚠️ Custom emergency alert sound not found in bundle")
        }
    }

    private func setupNotificationCategories() {
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_NOTIFICATION",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([timerCategory])
    }

    private func scheduleTimerNotification(title: String, body: String, timeInterval: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = "🚨 ТРИВОГА" // Добавляем subtitle для большей серьезности
        content.body = body

        // Пытаемся использовать кастомный звук для уведомлений
        // Для iOS уведомлений файл должен быть в корне Bundle, но мы можем попробовать из Sounds/
        if customSoundLoaded {
            // Пробуем найти файл в корне Bundle (правильное место для уведомлений)
            if let _ = Bundle.main.url(forResource: "emergency_alert", withExtension: "wav") {
                content.sound = UNNotificationSound(named: UNNotificationSoundName("emergency_alert.wav"))
                print("🎵 Using custom sound from bundle root for notification")
            } else {
                // Если файл не в корне, используем системный звук
                content.sound = UNNotificationSound.default
                print("⚠️ Custom sound not in bundle root, using default notification sound")
            }
        } else {
            content.sound = UNNotificationSound.default

            // Делаем уведомление максимально заметным
            content.badge = NSNumber(value: 1)
            content.subtitle = "КРИТИЧНА ТРИВОГА"
        }
        content.categoryIdentifier = "TIMER_NOTIFICATION"

        // Добавляем максимальную вибрацию и повторяющиеся звуки
        content.userInfo = [
            "shouldVibrate": true,
            "soundId": UInt32(kSystemSoundID_Vibrate),
            "repeatSound": true
        ]

        // Устанавливаем максимальный уровень прерывания
        // content.threadIdentifier удален, чтобы избежать группировки, которая может скрывать уведомления
        
        // Используем .timeSensitive для прорыва через Focus режимы и гарантии отображения
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        } else {
            // Fallback on earlier versions
        }

        // Добавляем badge для видимости
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
