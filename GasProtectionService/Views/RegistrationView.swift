//
//  RegistrationView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var controller = AuthenticationController()
    @Binding var isPresented: Bool
    @State private var showPasswords = false // Общее состояние для обоих полей

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 30) {
                    // Logo/Title
                    VStack(spacing: 15) {
                        Image(systemName: "person.badge.plus")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)

                        Text("ГДЗС")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Реєстрація")
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

                            TextField("Введіть ваш email", text: $controller.credentials.email)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(controller.isLoading)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Пароль")
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack {
                                if showPasswords {
                                    TextField("Введіть пароль", text: $controller.credentials.password)
                                        .disabled(controller.isLoading)
                                } else {
                                    SecureField("Введіть пароль", text: $controller.credentials.password)
                                        .disabled(controller.isLoading)
                                }

                                Button(action: {
                                    showPasswords.toggle()
                                }) {
                                    Image(systemName: showPasswords ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                                .disabled(controller.isLoading)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Підтвердіть пароль")
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack {
                                if showPasswords {
                                    TextField("Повторіть пароль", text: $controller.credentials.confirmPassword)
                                        .disabled(controller.isLoading)
                                } else {
                                    SecureField("Повторіть пароль", text: $controller.credentials.confirmPassword)
                                        .disabled(controller.isLoading)
                                }

                                Button(action: {
                                    showPasswords.toggle()
                                }) {
                                    Image(systemName: showPasswords ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                                .disabled(controller.isLoading)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // Register Button
                    Button(action: {
                        controller.registerUser { result in
                            switch result {
                            case .success(let user):
                                appState.login(with: user)
                                isPresented = false // Close registration view
                            case .failure(let error):
                                print("Registration error: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        if controller.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Зареєструватися")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(controller.isLoading)

                    Spacer()
                }
                .padding()

                // Custom Alert
                if controller.showCustomAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            controller.dismissAlert()
                        }

                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Text("Повідомлення")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)

                            Text(controller.alertMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button(action: controller.dismissAlert) {
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
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .hideKeyboardOnTapAndSwipe()
            .navigationBarItems(leading: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                Text("Назад")
            })
            .navigationBarTitle("", displayMode: .inline)
        }
    }
}

#Preview {
    RegistrationView(isPresented: .constant(true))
        .environmentObject(AppState())
}
