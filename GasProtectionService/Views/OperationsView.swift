//
//  OperationsView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct OperationsView: View {
    @EnvironmentObject var appState: AppState
    @State private var isCreatingCommand = false
    @State private var selectedCommand: CheckCommand?


    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Оберіть потрібну ланку")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 20)

            // Main Content
            if appState.checkController.teamCommands.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "wrench.and.screwdriver")
                        .resizable()
                        .frame(width: 80, height: 60)
                        .foregroundColor(.orange.opacity(0.7))

                    Text("Немає створених ланок")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(appState.checkController.teamCommands) { command in
                            OperationCommandCard(command: command)
                                .onTapGesture {
                                    selectedCommand = command
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }

            // Create Button
            Button(action: {
                isCreatingCommand = true
            }) {
                Text("Створити нову ланку")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .fullScreenCover(item: $selectedCommand) { command in
            OperationsCalculatorView(availableCommand: command) { updatedCommand in
                appState.checkController.updateCommand(updatedCommand)
                selectedCommand = nil
            }
        }
        .fullScreenCover(isPresented: $isCreatingCommand) {
            OperationsCalculatorView { command in
                appState.checkController.addCommand(command)
                isCreatingCommand = false
            }
        }
    }
}

// MARK: - Operation Command Card (без кнопок редактирования/удаления)
struct OperationCommandCard: View {
    let command: CheckCommand

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(command.commandName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            // Date & Device Type
            HStack {
                // Дата зліва
                Text(command.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer() // Розштовхує елементи по краях

                // Тип апарату справа
                Text(command.deviceType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Team Members
            VStack(alignment: .leading, spacing: 8) {
                ForEach(command.teamMembers) { member in
                    HStack {
                        Image(systemName: member.hasRescueDevice ?
                              "person.crop.circle.badge.checkmark" :
                              "person.crop.circle.badge.questionmark")
                            .foregroundColor(member.hasRescueDevice ? .green : .gray)

                        Text(member.fullName)
                            .font(.body)

                        Spacer()

                        Text("\(member.pressure) бар")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Operation Card
struct OperationCard: View {
    let operation: OperationData
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(operation.operationType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(operation.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(operation.deviceType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Team Members
            VStack(alignment: .leading, spacing: 8) {
                ForEach(operation.members.filter { $0.isActive }) { member in
                    HStack {
                        Image(systemName: member.role.iconName)
                            .foregroundColor(
                                member.role.iconColor == "systemOrange" ? .orange :
                                member.role.iconColor == "systemRed" ? .red :
                                member.role.iconColor == "systemGreen" ? .green : .gray
                            )

                        Text(member.fullName)
                            .font(.body)

                        Spacer()

                        Text("\(member.pressure) бар")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Settings
            if operation.settings.workBelowLimit {
                Text("Працювати при тиску нижче ліміту")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }

            if let entryTime = operation.settings.entryTime {
                Text("Час входу: \(operation.formattedEntryTime)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            // Delete Button
            Button(action: onDelete) {
                Text("Видалити операцію")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    OperationsView()
}

