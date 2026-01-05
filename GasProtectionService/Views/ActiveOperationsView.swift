//
//  ActiveOperationsView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import SwiftUI

struct ActiveOperationsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    var onOperationSelected: (OperationWorkData) -> Void

    // Только активные (незавершенные) операции
    private var activeOperations: [OperationWorkData] {
        return appState.activeOperationsManager.activeOperations.filter { operation in
            // Операция считается завершенной, если она вышла из зоны опасности и сохранен адрес
            !(operation.isExitingDangerZone && !operation.workAddress.isEmpty)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if activeOperations.isEmpty {
                    emptyStateView
                } else {
                    operationsListView
                }
            }
            .navigationTitle("Активні операції")
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))

            Text("Немає активних операцій")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Розпочніть операцію, щоб вона з'явилась тут")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var operationsListView: some View {
        let operations = activeOperations
        return List {
            ForEach(operations, id: \.id) { operation in
                    Button(action: {
                        onOperationSelected(operation)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(operation.operationData.commandName ?? operation.operationData.operationType.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Spacer()

                                Text(operation.operationData.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Text("Час входу: \(operation.operationData.formattedEntryTime)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)

                                Spacer()

                                Text("\(operation.operationData.members.filter { $0.isActive }.count) активних")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Показываем активных членов ланки
                            let activeMembers = operation.operationData.members.filter { $0.isActive }
                            if !activeMembers.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(activeMembers.prefix(3)) { member in
                                        HStack {
                                            Text(member.fullName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(member.pressure) бар")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    if activeMembers.count > 3 {
                                        Text("та ще \(activeMembers.count - 3) осіб...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            if operation.isWorkingInDangerZone {
                                Text("🔥 Працюють в небезпечній зоні")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if operation.hasFoundFireSource {
                                Text("🎯 Знайдено джерело вогню")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                    }
                }
            }
        }
    }


#Preview {
    let appState = AppState()
    // Добавим тестовую операцию для демонстрации
    let testOperation = OperationWorkData(
        operationData: OperationData(
            operationType: .fire,
            deviceType: .dragerPSS3000,
            members: [
                OperationMember(role: .squadLeader, fullName: "Іванов Іван", pressure: "300", isActive: true),
                OperationMember(role: .firefighter, fullName: "Петров Петро", pressure: "300", isActive: true)
            ]
        )
    )
    appState.activeOperationsManager.addActiveOperation(testOperation)

    return ActiveOperationsView(onOperationSelected: { _ in })
        .environmentObject(appState)
}
