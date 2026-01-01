//
//  AboutAppView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import SwiftUI

struct AboutAppView: View {
    @Environment(\.presentationMode) var presentationMode

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Title
                    HStack(spacing: 16) {
                        Image(uiImage: UIImage(named: "AppIcon") ?? UIImage(systemName: "flame.fill")!)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .cornerRadius(16)
                            .shadow(radius: 4)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Калькулятор поста безпеки")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Версія:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(appVersion)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal)

                    // App Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Додаток для розрахунку часу та тиску роботи пожежних підрозділів")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Основні функції:")
                                .font(.headline)
                                .foregroundColor(.primary)

                            VStack(alignment: .leading, spacing: 8) {
                                FeatureRow(text: "Розрахунок часу роботи пожежних підрозділів")
                                FeatureRow(text: "Ведення роботи одразу декількох ланок")
                                FeatureRow(text: "Ведення журналу роботи ланки ГДЗС")
                                FeatureRow(text: "Збереження ланок та адрес робботи")
                                FeatureRow(text: "QR-сканер та редактор")
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Author Information
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Автор:")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Сунко Дмитро Володимирович")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Контакти для пропозицій та зауважень:")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("d.sunko@dsns.gov.ua")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)

                }
                .padding(.top)
            }
            .navigationTitle("Про додаток")
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .frame(width: 20, height: 20)

            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    AboutAppView()
}
