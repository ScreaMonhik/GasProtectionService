//
//  OperationsCalculatorView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 26.12.2025.
//

import SwiftUI

struct OperationsCalculatorView: View {
    @StateObject private var controller: OperationCreationController
    @Environment(\.presentationMode) var presentationMode
    @State private var isWorking = false
    var onSave: (CheckCommand) -> Void

    init(availableCommand: CheckCommand? = nil, onSave: @escaping (CheckCommand) -> Void) {
        self.onSave = onSave
        _controller = StateObject(wrappedValue: OperationCreationController(availableCommand: availableCommand))
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Калькулятор поста безпеки")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Створення операції")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)

                        // Operation Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Оберіть тип роботи:")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Button(action: {
                                controller.showingOperationTypePicker.toggle()
                            }) {
                                HStack {
                                    Text(controller.newCommand.operationType.displayName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)

                        // Device Type (only show when creating new)
                        if !controller.isEditingExisting {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Тип апарату:")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Button(action: {
                                    controller.showingDevicePicker.toggle()
                                }) {
                                    HStack {
                                        Text(controller.newCommand.deviceType.displayName)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Team Members Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Члени ланки:")
                                .font(.headline)
                                .foregroundColor(.primary)

                            ForEach(controller.newCommand.members.indices, id: \.self) { index in
                                OperationMemberRow(
                                    member: $controller.newCommand.members[index],
                                    onRoleTap: {
                                        controller.showRolePicker(for: index)
                                    },
                                    onActiveToggle: {
                                        controller.toggleMemberActive(index)
                                    },
                                    onDelete: {
                                        controller.removeMemberAt(index)
                                    },
                                    canDelete: controller.canRemoveMemberAt(index)
                                )
                                .id(index)
                            }
                        }
                        .padding(.horizontal)

                        // Add Button
                        Button(action: {
                            controller.addMember()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollView.scrollTo(controller.newCommand.members.count - 1, anchor: .bottom)
                                }
                            }
                        }) {
                            Text("Додати")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Divider()
                                .padding(.vertical, 8)

                            // Work Below Limit Toggle
                            HStack {
                                Text("Працювати при тиску нижче ліміту")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Toggle("", isOn: $controller.newCommand.settings.workBelowLimit)
                                    .labelsHidden()
                            }

                            // Entry Time
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Час входу ланки в задимлену зону:")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                DatePicker(
                                    controller.newCommand.formattedEntryTime,
                                    selection: Binding(
                                        get: { controller.newCommand.settings.entryTime ?? Date() },
                                        set: { controller.setEntryTime($0) }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)

                        // Start Work Button
                    Button(action: {
                        if controller.isValidOperation() {
                            // Устанавливаем текущее время, если время входа не выбрано
                            if controller.newCommand.settings.entryTime == nil {
                                controller.newCommand.settings.entryTime = Date()
                            }
                            isWorking = true
                        }
                    }) {
                            Text("Почати роботу")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(controller.isValidOperation() ? Color.green : Color.gray)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
                .hideKeyboardOnTapAndSwipe()
                .navigationBarItems(leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                    Text("Назад")
                })
                .navigationBarTitle("", displayMode: .inline)
            }
            .sheet(isPresented: $controller.showingOperationTypePicker) {
                OperationTypePickerView(selectedType: $controller.newCommand.operationType)
            }
            .sheet(isPresented: $controller.showingDevicePicker) {
                DevicePickerView(selectedDevice: $controller.newCommand.deviceType)
            }
            .sheet(isPresented: $controller.showingRolePicker) {
                TeamRolePickerView(onRoleSelected: { role in
                    controller.selectRole(role)
                })
            }
            .fullScreenCover(isPresented: $isWorking) {
                OperationWorkView(operationData: controller.newCommand, onSave: onSave)
            }
        }
    }
}

// MARK: - Operation Member Row
struct OperationMemberRow: View {
    @Binding var member: OperationMember
    var onRoleTap: () -> Void
    var onActiveToggle: () -> Void
    var onDelete: () -> Void
    var canDelete: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Role Icon
            Button(action: onRoleTap) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 40)
                    Image(systemName: member.role.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(member.role.color)
                }
            }
            .frame(width: 40, height: 40)

            // Active Toggle
            Button(action: onActiveToggle) {
                Image(systemName: member.isActive ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(member.isActive ? .green : .gray)
                    .frame(width: 40, height: 40)
            }

            // Name Field
            TextField("Прізвище та ім'я", text: $member.fullName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            // Pressure Field
            TextField("Тиск", text: $member.pressure)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(width: 80)
                .keyboardType(.decimalPad)

            // Delete Button
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding()
        .background(Color(.systemGray5).opacity(0.3))
        .cornerRadius(12)
        .opacity(member.isActive ? 1.0 : 0.5)
    }
}

// MARK: - Operation Type Picker
struct OperationTypePickerView: View {
    @Binding var selectedType: OperationType
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List(OperationType.allCases, id: \.self) { type in
                Button(action: {
                    selectedType = type
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(type.displayName)
                        Spacer()
                        if selectedType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Тип роботи")
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Team Role Picker
struct TeamRolePickerView: View {
    var onRoleSelected: (TeamMemberRole) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List(TeamMemberRole.allCases, id: \.self) { role in
                Button(action: {
                    onRoleSelected(role)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: role.iconName)
                            .foregroundStyle(role.color)
                            .frame(width: 30, height: 30)
                        Text(role.displayName)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Виберіть роль")
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    OperationsCalculatorView { command in
        print("Created command: \(command.commandName)")
    }
}
