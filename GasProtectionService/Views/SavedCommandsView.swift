//
//  SavedCommandsView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import SwiftUI

struct SavedCommandsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    var onCommandSelected: (CheckCommand) -> Void
    var onCreateNewCommand: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                if availableCommands.isEmpty {
                    emptyAvailableCommandsView
                } else {
                    availableCommandsListView
                }
            }
            .navigationTitle("Створити паралельну операцію")
            .navigationBarItems(trailing: Button("Скасувати") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    // Доступные команды (те, для которых нет активных операций)
    private var availableCommands: [CheckCommand] {
        let activeOperations = appState.activeOperationsManager.activeOperations
        let activeCommandNames = Set(activeOperations.compactMap { $0.operationData.commandName })

        let available = appState.checkController.teamCommands.filter { command in
            !activeCommandNames.contains(command.commandName)
        }

        return available
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))

            Text("Немає збережених ланок")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Створіть свою першу ланку для початку роботи")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onCreateNewCommand) {
                Text("Створити нову ланку")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .padding()
    }

    private var emptyAvailableCommandsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(.green.opacity(0.7))

            Text("Всі ланки вже в роботі")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Усі збережені ланки вже мають активні операції")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var availableCommandsListView: some View {
        List {
            ForEach(availableCommands) { command in
                Button(action: {
                    onCommandSelected(command)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(command.commandName)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(command.teamMembers.count) осіб")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text(command.deviceType.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(command.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Кнопка создания новой команды
            Section {
                Button(action: onCreateNewCommand) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Створити нову ланку")
                            .foregroundColor(.blue)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

#Preview {
    let appState = AppState()
    // Добавим тестовую команду для демонстрации
    let testCommand = CheckCommand(
        commandName: "Ланка №1",
        teamMembers: [
            TeamMember(fullName: "Іванов Іван", pressure: "300", hasRescueDevice: true),
            TeamMember(fullName: "Петров Петро", pressure: "300", hasRescueDevice: false)
        ]
    )
    appState.checkController.addCommand(testCommand)

    return SavedCommandsView(
        onCommandSelected: { _ in },
        onCreateNewCommand: {}
    )
    .environmentObject(appState)
}
