//
//  OperationDetailsView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 30.12.2025.
//

import SwiftUI

struct OperationDetailsView: View {
    let command: CheckCommand
    @Environment(\.presentationMode) var presentationMode

    private var workData: OperationWorkData? {
        OperationWorkController.loadWorkDataForCommand(command.id)
    }

    private var protectionTime: Int {
        if let workData = workData {
            return workData.protectionTime
        }
        // Fallback calculation if WorkData is missing
        let pressures = command.teamMembers.compactMap { Int($0.pressure) }
        let minPressure = pressures.min() ?? 0
        return GasCalculator.calculateProtectionTime(minPressure: minPressure, deviceType: command.deviceType)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Block 1: Equipment protection time
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Час захисної дії апаратів:")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Spacer()
                            Text("\(protectionTime) хв.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Час роботи біля осередку пожежі:")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("7 XB.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Block 2: Time information
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Час входу:")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(workData?.operationData.formattedEntryTime ?? "Невідомо")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Час початку гасіння:")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(workData?.formattedDangerZoneStartTime ?? "Невідомо")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Час виходу:")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(workData?.formattedDangerZoneExitTime ?? "Невідомо")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Block 3: Pressure information
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Тиск використаний на шлях")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("155 бар.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Мін. тиск перед виходом")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(workData?.minimumExitPressure ?? "Невідомо") бар.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Тиск при знаходженні осередка")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(workData?.lowestPressure ?? "Невідомо") бар.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Block 4: Activity type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Тип активності")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Пожежа")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Block 5: Team composition
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Склад ланки ГДЗС")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(command.teamMembers) { member in
                                HStack {
                                    Text("\(member.fullName) - \(getRoleDisplayName(member))")
                                        .font(.body)
                                        .foregroundColor(.primary)
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

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .navigationBarTitle("Деталі операції", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                Text("Назад")
            })
            .hideKeyboardOnTapAndSwipe()
        }
    }

    private func getRoleDisplayName(_ member: TeamMember) -> String {
        // Since we don't have role information in CheckCommand,
        // we'll use default roles or try to get from workData
        if let workData = workData,
           let operationMember = workData.operationData.members.first(where: { $0.fullName == member.fullName }) {
            return operationMember.role.displayName
        }
        return "пожежний" // Default role
    }
}

#Preview {
    let command = CheckCommand(
        commandName: "Тестова операція",
        deviceType: .dragerPSS3000,
        teamMembers: [
            TeamMember(fullName: "Іван Петренко", pressure: "300"),
            TeamMember(fullName: "Марія Василенко", pressure: "290")
        ],
        commandType: .operation
    )

    return OperationDetailsView(command: command)
}
