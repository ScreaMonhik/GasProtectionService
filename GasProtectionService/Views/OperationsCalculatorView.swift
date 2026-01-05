//
//  OperationsCalculatorView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 26.12.2025.
//

import SwiftUI
import Combine

struct OperationsCalculatorView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @ObservedObject private var controller: OperationCreationController
    @State private var isWorking = false
    @State private var selectedOperationType: OperationType = .fire
    @State private var selectedDeviceType: DeviceType = .dragerPSS3000
    @State private var showingOperationTypePicker = false
    @State private var showingDevicePicker = false
    @State private var showingRolePicker = false
    @State private var rolePickerMemberIndex: Int?
    var onSave: (CheckCommand) -> Void

    // Вычисляемое свойство для проверки валидности
    var isOperationValid: Bool {
        let activeCount = controller.newCommand.members.filter { $0.isActive }.count
        return activeCount >= 2
    }

    init(availableCommand: CheckCommand? = nil, onSave: @escaping (CheckCommand) -> Void) {
        self.onSave = onSave
        let controller = OperationCreationController(availableCommand: availableCommand)
        self._controller = ObservedObject(initialValue: controller)
        // Инициализируем локальные переменные значениями из контроллера
        self._selectedOperationType = State(initialValue: controller.newCommand.operationType)
        self._selectedDeviceType = State(initialValue: controller.newCommand.deviceType)
    }

    var body: some View {
        NavigationView {
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
                                print("=== BUTTON PRESSED ===")
                                print("Operation type picker button pressed, current state: \(showingOperationTypePicker)")
                                // Убираем sheetId для теста
                                showingOperationTypePicker.toggle()
                                print("Operation type picker state after toggle: \(showingOperationTypePicker)")
                                print("=== BUTTON END ===")
                            }) {
                                HStack {
                                    Text(selectedOperationType.displayName)
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
                                    print("Device picker button pressed")
                                    showingDevicePicker.toggle()
                                }) {
                                    HStack {
                                        Text(selectedDeviceType.displayName)
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

                            ForEach(controller.newCommand.members, id: \.id) { member in
                                let memberIndex = controller.newCommand.members.firstIndex(where: { $0.id == member.id }) ?? 0

                                let memberBinding = Binding(
                                    get: { member },
                                    set: {
                                        if let index = self.controller.newCommand.members.firstIndex(where: { $0.id == member.id }) {
                                            self.controller.newCommand.members[index] = $0
                                        }
                                    }
                                )

                                let activeBinding = Binding(
                                    get: { member.isActive },
                                    set: {
                                        if let index = self.controller.newCommand.members.firstIndex(where: { $0.id == member.id }) {
                                            self.controller.newCommand.members[index].isActive = $0
                                        }
                                    }
                                )

                                OperationMemberRow(
                                    member: memberBinding,
                                    isActive: activeBinding,
                                    onRoleTap: {
                                        if let index = self.controller.newCommand.members.firstIndex(where: { $0.id == member.id }) {
                                            self.rolePickerMemberIndex = index
                                            self.showingRolePicker = true
                                        }
                                    },
                                    onDelete: {
                                        if let index = self.controller.newCommand.members.firstIndex(where: { $0.id == member.id }) {
                                            self.controller.removeMemberAt(index)
                                        }
                                    },
                                    canDelete: {
                                        if let index = self.controller.newCommand.members.firstIndex(where: { $0.id == member.id }) {
                                            return self.controller.canRemoveMemberAt(index)
                                        }
                                        return false
                                    }()
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Add Button
                        Button(action: {
                            print("Add member button pressed")
                            controller.addMember()
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
                        if isOperationValid {
                            // Синхронизируем локальные состояния с контроллером
                            controller.newCommand.operationType = selectedOperationType
                            controller.newCommand.deviceType = selectedDeviceType

                            // Устанавливаем текущее время, если время входа не выбрано
                            if controller.newCommand.settings.entryTime == nil {
                                controller.newCommand.settings.entryTime = Date()
                            }
                            print("=== STARTING OPERATION ===")
                            print("Command name: \(controller.newCommand.commandName ?? "nil")")
                            print("Operation type: \(controller.newCommand.operationType.displayName)")
                            print("Active operations before: \(appState.activeOperationsManager.activeOperations.count)")
                            // Оставляем commandName как есть - он установлен в OperationCreationController
                            let operationData = controller.newCommand
                            let workData = OperationWorkData(operationData: operationData)
                            appState.activeOperationsManager.addActiveOperation(workData)
                            print("Active operations after: \(appState.activeOperationsManager.activeOperations.count)")
                            print("Current operation ID: \(appState.activeOperationsManager.currentOperationId?.uuidString ?? "nil")")
                            print("=== OPERATION STARTED ===")
                            isWorking = true
                        }
                    }) {
                            Text("Почати роботу")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isOperationValid ? Color.green : Color.gray)
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
            .sheet(isPresented: $showingOperationTypePicker) {
                OperationTypePickerView(selectedType: $selectedOperationType)
                    .onAppear {
                        print("Operation type picker sheet opened")
                    }
            }
            .sheet(isPresented: $showingDevicePicker) {
                DevicePickerView(selectedDevice: $selectedDeviceType)
            }
            .sheet(isPresented: $showingRolePicker) {
                TeamRolePickerView(onRoleSelected: { role in
                    if let index = rolePickerMemberIndex {
                        controller.newCommand.members[index].role = role
                    }
                    showingRolePicker = false
                })
            }
            .fullScreenCover(isPresented: $isWorking) {
                OperationWorkView(onSave: onSave, appState: appState)
            }
            .sheet(isPresented: $appState.checkController.isCreatingCommand) {
                CreateCommandView { newCommand in
                    // После создания команды, автоматически выбираем её
                    let newController = OperationCreationController(availableCommand: newCommand)
                    self.controller.newCommand = newController.newCommand
                    self.controller.isEditingExisting = newController.isEditingExisting
                    self.controller.objectWillChange.send()
                }
            }
        }
    }

    // MARK: - Operation Member Row
struct OperationMemberRow: View {
    @Binding var member: OperationMember
    @Binding var isActive: Bool
    var onRoleTap: () -> Void
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
            Button(action: { isActive.toggle() }) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(isActive ? .green : .gray)
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
        .opacity(isActive ? 1.0 : 0.5)
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
