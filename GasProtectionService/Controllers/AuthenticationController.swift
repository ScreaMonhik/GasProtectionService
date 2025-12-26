//
//  AuthenticationController.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import Foundation
import Combine

class AuthenticationController: ObservableObject {
    // MARK: - Published Properties

    @Published var credentials = AuthenticationCredentials()
    @Published var isLoading = false
    @Published var alertMessage = ""
    @Published var showCustomAlert = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Methods


    func loginUser(completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true

        // Basic validation
        guard !credentials.email.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Будь ласка, введіть email")
            return
        }

        guard isValidEmail(credentials.email) else {
            showError("Будь ласка, введіть коректний email")
            return
        }

        guard !credentials.password.isEmpty else {
            showError("Будь ласка, введіть пароль")
            return
        }

        // Simulate login process (replace with actual API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [weak self] in
            guard let self = self else { return }
            self.isLoading = false

            // Here you would typically authenticate with your backend
            print("Спроба входу:")
            print("Email: \(self.credentials.email)")

            // For demo purposes, accept any valid email/password combination
            // In real app, you would check against your backend
            if self.credentials.email.contains("@") && self.credentials.password.count >= 4 {
                self.showSuccess("Вхід успішний!")
                // Navigate to main screen after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    completion(.success(User.mockUser))
                })
            } else {
                self.showError("Невірний email або пароль")
            }
        })
    }

    func registerUser(completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true

        // Basic validation
        guard !credentials.email.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Будь ласка, введіть email")
            return
        }

        guard isValidEmail(credentials.email) else {
            showError("Будь ласка, введіть коректний email")
            return
        }

        guard !credentials.password.isEmpty else {
            showError("Будь ласка, введіть пароль")
            return
        }

        guard credentials.password.count >= 6 else {
            showError("Пароль повинен містити мінімум 6 символів")
            return
        }

        guard !credentials.confirmPassword.isEmpty else {
            showError("Будь ласка, підтвердіть пароль")
            return
        }

        guard credentials.password == credentials.confirmPassword else {
            showError("Паролі не співпадають")
            return
        }

        // Simulate registration process (replace with actual API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak self] in
            guard let self = self else { return }
            self.isLoading = false

            // Here you would typically register with your backend
            print("Спроба реєстрації:")
            print("Email: \(self.credentials.email)")

            // For demo purposes, accept any valid registration
            self.showSuccess("Реєстрація успішна! Вхід виконується...")

            // Auto-login after successful registration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                completion(.success(User.mockUser))
            })
        })
    }

    func dismissAlert() {
        showCustomAlert = false
        alertMessage = ""
    }

    // MARK: - Private Methods

    private func showError(_ message: String) {
        isLoading = false
        alertMessage = message
        showCustomAlert = true
    }

    private func showSuccess(_ message: String) {
        alertMessage = message
        showCustomAlert = true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
