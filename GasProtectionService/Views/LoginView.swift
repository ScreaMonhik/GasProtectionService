//
//  RegistrationScreen.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var controller = AuthenticationController()
    @State private var showRegistration = false
    @State private var showPassword = false

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
                                if showPassword {
                                    TextField("Введіть пароль", text: $controller.credentials.password)
                                        .disabled(controller.isLoading)
                                } else {
                                    SecureField("Введіть пароль", text: $controller.credentials.password)
                                        .disabled(controller.isLoading)
                                }

                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
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

                    // Login Button
                    Button(action: {
                        controller.loginUser { result in
                            switch result {
                            case .success(let user):
                                appState.login(with: user)
                            case .failure(let error):
                                print("Login error: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        if controller.isLoading {
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
                    .disabled(controller.isLoading)

                    // Registration Button
                    Button(action: {
                        showRegistration = true
                    }) {
                        Text("Реєстрація")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(controller.isLoading)

                    Spacer()
                }
                .padding()

                // Custom Alert
                if controller.showCustomAlert {
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
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
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showRegistration) {
                RegistrationView(isPresented: $showRegistration)
                    .environmentObject(appState)
            }
        }
    }

}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
