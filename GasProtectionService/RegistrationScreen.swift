//
//  RegistrationScreen.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct RegistrationScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showCustomAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 30) {
                    // Logo/Title
                    VStack(spacing: 15) {
                        Image(systemName: "shield.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)

                        Text("ГДЗС")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Вхід в систему")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 0)

                    // Form Fields
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Електронна пошта")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("Введіть ваш email", text: $email)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(isLoading)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Пароль")
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack {
                                if isPasswordVisible {
                                    TextField("Введіть пароль", text: $password)
                                        .disabled(isLoading)
                                } else {
                                    SecureField("Введіть пароль", text: $password)
                                        .disabled(isLoading)
                                }

                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                                .disabled(isLoading)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // Login Button
                    Button(action: loginUser) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Увійти")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isLoading)

                    Spacer()
                }
                .padding()

                // Custom Alert
                if showCustomAlert {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showCustomAlert = false
                        }

                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Text("Помилка")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)

                            Text(alertMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button(action: {
                            showCustomAlert = false
                        }) {
                            Text("OK")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: 300)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func loginUser() {
        isLoading = true

        // Basic validation
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Будь ласка, введіть email"
            showCustomAlert = true
            isLoading = false
            return
        }

        guard isValidEmail(email) else {
            alertMessage = "Будь ласка, введіть коректний email"
            showCustomAlert = true
            isLoading = false
            return
        }

        guard !password.isEmpty else {
            alertMessage = "Будь ласка, введіть пароль"
            showCustomAlert = true
            isLoading = false
            return
        }

        // Simulate login process (replace with actual API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false

            // Here you would typically authenticate with your backend
            print("Спроба входу:")
            print("Email: \(self.email)")

            // For demo purposes, accept any valid email/password combination
            // In real app, you would check against your backend
            if self.email.contains("@") && self.password.count >= 4 {
                self.alertMessage = "Вхід успішний!"
                self.showCustomAlert = true
                // Here you would navigate to main app screen
            } else {
                self.alertMessage = "Невірний email або пароль"
                self.showCustomAlert = true
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    RegistrationScreen()
}
