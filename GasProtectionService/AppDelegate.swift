//
//  AppDelegate.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import UIKit
import UserNotifications
import AudioToolbox

extension UIApplication {
    var topViewController: UIViewController? {
        // Для SwiftUI приложений попробуем другой подход
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ No window scene or window found")
            return nil
        }

        print("✅ Found window: \(window)")
        print("   Root VC: \(window.rootViewController)")

        var topController = window.rootViewController

        // Ищем самый верхний presented view controller
        while let presentedController = topController?.presentedViewController {
            print("   Found presented VC: \(presentedController)")
            topController = presentedController
        }

        print("   Final top VC: \(topController)")
        return topController
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Properties

    private var customAlertSoundID: SystemSoundID = 0
    private var customSoundLoaded = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Загружаем кастомный звук тревоги
        loadCustomAlertSound()

        // Настраиваем делегат для уведомлений
        UNUserNotificationCenter.current().delegate = self

        // Запрашиваем разрешения на уведомления при первом запуске
        requestNotificationPermissions()

        return true
    }

    private func requestNotificationPermissions() {
        // Настраиваем категории уведомлений заранее
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_NOTIFICATION",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([timerCategory])

        // Запрашиваем разрешения
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification authorization error: \(error.localizedDescription)")
                return
            }

            if granted {
                // Проверяем критически важные настройки для экстренного приложения
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.lockScreenSetting != .enabled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.showLockScreenWarning()
                        }
                    }
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Для таймеров - показываем уведомление всегда с максимальным звуком И ВИЗУАЛЬНЫМ АЛЕРТОМ
        if notification.request.content.categoryIdentifier == "TIMER_NOTIFICATION" {
            let title = notification.request.content.title
            let body = notification.request.content.body

            // Многоуровневая звуковая атака для максимального внимания
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            self.playSeriousAlertSound() // Серия серьезных звуков

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                self.playSeriousAlertSound()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                AudioServicesPlaySystemSound(1110) // Максимально тревожный звук
                AudioServicesPlaySystemSound(1304) // Финальный акцент
            }

            // ДОПОЛНИТЕЛЬНАЯ ЗАЩИТА: показываем UIAlertController для гарантии видимости
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showEmergencyAlert(title: title, message: body)
            }

            // Финальная серия через секунду - АПОКАЛИПСИС ЗВУКА
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                AudioServicesPlaySystemSound(1110) // Максимально тревожный
                AudioServicesPlaySystemSound(1110) // Дублируем
                AudioServicesPlaySystemSound(1304) // Финальный громкий акцент
            }
        }

        // Показываем уведомление всегда с полными опциями для максимальной видимости
        let options: UNNotificationPresentationOptions = [.alert, .banner, .sound, .badge, .list]
        completionHandler(options)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        // Проигрываем звук при нажатии на уведомление таймера
        if response.notification.request.content.categoryIdentifier == "TIMER_NOTIFICATION" {
            // Серия сигналов подтверждения - серьезный звук
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            AudioServicesPlaySystemSound(1304)
            AudioServicesPlaySystemSound(1108) // Серьезный звук подтверждения

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                AudioServicesPlaySystemSound(1110) // Максимально серьезный звук
            }

            // Убираем badge когда пользователь тапает на уведомление
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        // Обработка нажатия на уведомление
        let identifier = response.notification.request.identifier

        switch identifier {
        case "exit_timer_notification":
            print("Exit timer notification tapped")
        case "remaining_timer_notification":
            print("Remaining timer notification tapped")
        case "communication_timer_notification":
            print("Communication timer notification tapped")
        default:
            break
        }

        completionHandler()
    }

    // MARK: - Sound Methods

    private func loadCustomAlertSound() {
        // Загружаем кастомный звук тревоги для уведомлений
        if let soundURL = Bundle.main.url(forResource: "emergency_alert", withExtension: "wav", subdirectory: "Sounds") {
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &customAlertSoundID)
            customSoundLoaded = true
        } else {
            customSoundLoaded = false
        }
    }

    /// Проигрывает серьезный звук тревоги (кастомный или системный)
    private func playSeriousAlertSound() {
        if customSoundLoaded && customAlertSoundID != 0 {
            AudioServicesPlaySystemSound(customAlertSoundID)
        } else {
            // Используем комбинацию системных звуков для максимальной серьезности
            AudioServicesPlaySystemSound(1304) // Основной тревожный звук
            AudioServicesPlaySystemSound(1100) // Дополнительный серьезный тон

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AudioServicesPlaySystemSound(1108) // Более тревожный
            }
        }
    }

    // MARK: - Emergency Alert Methods

    /// Показывает экстренный UIAlertController для гарантии видимости уведомления
    private func showEmergencyAlert(title: String, message: String) {
        guard let topVC = UIApplication.shared.topViewController else {
            return
        }

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "ОК", style: .destructive, handler: nil))
        alert.view.tintColor = .red

        DispatchQueue.main.async {
            topVC.present(alert, animated: true)
        }
    }

    /// Показывает предупреждение о отключенных уведомлениях на lock screen
    private func showLockScreenWarning() {
        guard let topVC = UIApplication.shared.topViewController else {
            return
        }

        let alert = UIAlertController(
            title: "🚨 КРИТИЧНА ПРОБЛЕМА!",
            message: """
            Повідомлення на заблокованому екрані відключені!

            Для додатку ГДЗС це ДУЖЕ НЕБЕЗПЕЧНО!
            Ви можете не почути сигнал тривоги вчасно.

            ПЕРЕЙДІТЬ В НАЛАШТУВАННЯ:
            Settings → Notifications → GasProtectionService
            УВІМКНІТЬ: "Show on Lock Screen"
            """,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "ПЕРЕЙТИ В НАЛАШТУВАННЯ", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))

        alert.addAction(UIAlertAction(title: "ПІЗНІШЕ", style: .cancel, handler: nil))
        alert.view.tintColor = .red

        DispatchQueue.main.async {
            topVC.present(alert, animated: true)
        }
    }


    // MARK: - Application Lifecycle

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Убираем badge когда приложение становится активным
        // Пользователь увидел уведомления, открыв приложение
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // При полном закрытии приложения очищаем все активные операции
        print("🛑 Application will terminate - clearing all active operations")

        // Очищаем все запланированные уведомления таймеров
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        // Очищаем активные операции из UserDefaults
        UserDefaults.standard.removeObject(forKey: "active_operations")
        UserDefaults.standard.removeObject(forKey: "current_operation_id")

        print("✅ All active operations and notifications cleared on app termination")
    }

    // MARK: - Background Handling

}
