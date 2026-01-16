//
//  OperationWorkView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import SwiftUI
import Combine

struct OperationWorkView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var appState: AppState
    @State private var showingSavedCommands = false
    @State private var showingActiveOperations = false
    @State private var showingCreateCommand = false
    @State private var sheetId = UUID() // Для принудительной перерисовки sheets
    @StateObject private var controller: OperationWorkController
    @State private var displayExitTimer: TimeInterval = 0
    @State private var displayRemainingTimer: TimeInterval = 0
    @State private var displayCommunicationTimer: TimeInterval = 0
    @State private var manualPressureInput = ""
    var onSave: (CheckCommand) -> Void

    // Для отслеживания скрытия клавиатуры
    private let keyboardHidePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    
    
    // Инициализатор для работы с менеджером операций
    init(onSave: @escaping (CheckCommand) -> Void, appState: AppState) {
        self.onSave = onSave

        // Создаем контроллер с текущей операцией или пустой операцией
        let controller: OperationWorkController
        if let currentOperation = appState.activeOperationsManager.currentOperation {
            controller = OperationWorkController(existingOperation: currentOperation, appState: appState)
        } else {
            // Создаем пустую операцию для инициализации
            let emptyData = OperationData()
            let workData = OperationWorkController.createInitialWorkData(from: emptyData)
            controller = OperationWorkController(existingOperation: workData, appState: appState)
        }

        _controller = StateObject(wrappedValue: controller)
    }

    // Метод для обновления контроллера при смене операции
    private func updateControllerForCurrentOperation() {
        // Просто обновляем данные в существующем контроллере
        controller.loadCurrentDataFromManager()
        // Обновляем отображение таймеров
        updateDisplayFromGlobal()
    }

    private func startDisplayTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            // Обновляем отображение каждую секунду
            updateDisplayFromGlobal()
        }
    }

    private func stopDisplayTimer() {
        // Timer автоматически инвалидируется
    }

    private func updateDisplayFromGlobal() {
        // Обновляем отображение таймеров из глобального состояния
        guard let currentOperation = appState.activeOperationsManager.currentOperation else {
            return
        }

        // Обновляем только локальные переменные отображения
        let oldRemaining = displayRemainingTimer
        displayExitTimer = currentOperation.exitTimer
        displayRemainingTimer = currentOperation.remainingTimer
        displayCommunicationTimer = currentOperation.communicationTimer

        print("🔄 UI Update: remainingTimer \(oldRemaining) -> \(displayRemainingTimer) (from operation: \(currentOperation.remainingTimer))")

        if oldRemaining != displayRemainingTimer {
            print("🔄 UI Updated: remainingTimer \(oldRemaining) -> \(displayRemainingTimer)")
        }
    }


    var body: some View {
        NavigationView {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 24) {
                        
                    // Top Bar
                    HStack {
                        Button(action: {
                            print("Left button pressed - showing saved commands")
                            sheetId = UUID() // Изменяем ID перед открытием
                            showingSavedCommands.toggle()
                        }) {
                            Image(systemName: "person.2.badge.plus")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()

                        VStack(spacing: 4) {
                            if let commandName = controller.workData.operationData.commandName {
                                Text(commandName)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            } else {
                                // Для операций без названия показываем тип операции
                                Text(controller.workData.operationData.operationType.displayName)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        Text(controller.formatCurrentTime())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        }

                        Spacer()

                        Button(action: {
                            print("Right button pressed - showing active operations")
                            sheetId = UUID() // Изменяем ID перед открытием
                            showingActiveOperations.toggle()
                        }) {
                            Image(systemName: "link")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                        }
                    }
                        .padding(.horizontal)

                        // Calculation Data Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Розрахункові дані")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            // Entry and Expected Exit Times
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Час входу ланки в задимлену зону:")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(controller.workData.operationData.formattedEntryTime)
                                        .font(.body)
                                        .foregroundColor(.green)
                                        .bold()
                                }
                                
                                HStack {
                                    Text("Час виходу ланки:")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(controller.workData.expectedExitTime)
                                        .font(.body)
                                        .foregroundColor(.red)
                                        .bold()
                                }

                                // Добавлено: Час пошуку осередку (показывается только после нахождения очага)
                                if controller.workData.hasFoundFireSource {
                                    HStack {
                                        Text("Час пошуку осередку:")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(controller.workData.searchTime) хв")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Exit Timer (only if not found fire source)
                            if !controller.workData.hasFoundFireSource {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Таймер повернення якщо не знайдено осередку пожежі")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text("Таймер виходу")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(controller.formatTime(displayExitTimer))
                                            .font(.body)
                                            .foregroundColor(.red)
                                            .fontWeight(.bold)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            // Dismiss keyboard when tapping on timer areas
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }

                        // Manual Pressure Input Block - above timers
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Найменший тиск в ланці")
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack {
                                Text("Тиск:")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                TextField("Тиск", text: $manualPressureInput)
                                    .frame(width: 80)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: manualPressureInput) { newValue in
                                        // Обрабатываем ввод и ограничиваем (только валидация, без перерасчета)
                                        let processedValue = controller.processPressureInput(newValue)
                                        if processedValue != newValue {
                                            manualPressureInput = processedValue
                                        }

                                        // Обновляем lowestPressure сразу при изменении (без перерасчета расхода)
                                        if let pressureValue = Int(processedValue), pressureValue > 0 {
                                            controller.workData.lowestPressure = processedValue
                                            appState.activeOperationsManager.updateActiveOperation(controller.workData)
                                        }
                                    }
                            }

                            HStack {
                                Text("Розхід:")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(controller.workData.actualAirConsumption > 0 ? "\(Int(controller.workData.actualAirConsumption)) л/хв" : "\(Int(controller.workData.operationData.deviceType.airConsumption)) л/хв")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onReceive(keyboardHidePublisher) { _ in
                            // Перерасчет при скрытии клавиатуры
                            if let pressureValue = Int(manualPressureInput), pressureValue > 0 {
                                controller.recalculateRemainingTimer(for: pressureValue)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Timers Block - always above button
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Залишок")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(controller.formatTime(displayRemainingTimer))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .contentShape(Rectangle())

                            VStack(alignment: .leading) {
                                Text("Звʼязок")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(controller.formatTime(displayCommunicationTimer))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                        }
                        .padding(.horizontal)

                        Spacer()

                        // Action Button
                        Button(action: {
                            if !controller.workData.hasFoundFireSource {
                                controller.findFireSource()
                            } else if !controller.workData.isWorkingInDangerZone {
                                controller.startWorkInDangerZone()
                            } else if !controller.workData.isExitingDangerZone {
                                controller.startExitFromDangerZone()
                            } else {
                                controller.showingAddressAlert = true
                            }
                        }) {
                            Text(buttonTitle)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(buttonColor)
                                .cornerRadius(12)
                        }
                        .disabled(buttonDisabled)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                        
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {
                    controller.showingTeamInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                })
                .sheet(isPresented: $controller.showingTeamInfo) {
                    TeamInfoView(members: controller.workData.operationData.members.filter { $0.isActive })
                }
                .sheet(isPresented: $controller.showingAddressAlert) {
                    AddressInputView(
                        locationService: controller.locationService,
                        onSave: {
                            controller.workData.workAddress = controller.locationService.currentAddress
                            let command = controller.saveToJournal()
                            onSave(command)
                    // Проверяем и удаляем завершенную операцию
                    controller.checkAndRemoveCompletedOperation()
                            presentationMode.wrappedValue.dismiss()
                        },
                        onCancel: {
                            controller.showingAddressAlert = false
                        }
                    )
                }
            }
            .sheet(isPresented: $controller.showingPressureAlert) {
                VStack(spacing: 20) {
                    Text("Помилка")
                        .font(.title)
                        .foregroundColor(.red)
                        .bold()

                    Text(controller.pressureAlertMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        controller.showingPressureAlert = false
                        controller.alertAlreadyShown = false
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
                .padding()
                .presentationDetents([.fraction(0.3)])
            }
            .sheet(isPresented: $controller.showingConsumptionWarning) {
                VStack(spacing: 20) {
                    Text("⚠️ Попередження")
                        .font(.title)
                        .foregroundColor(.orange)
                        .bold()

                    Text(controller.consumptionWarningMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        controller.showingConsumptionWarning = false
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
                .padding()
                .presentationDetents([.fraction(0.4)])
            }
            .onChange(of: scenePhase) { newPhase in
                controller.handleScenePhaseChange(newPhase)
            }
            .onAppear {
                // Передаем appState в контроллер
                controller.setAppState(appState)
                // Запускаем локальный таймер для обновления отображения
                startDisplayTimer()
                // Инициализируем manualPressureInput текущим минимальным давлением
                manualPressureInput = String(controller.getMinPressureInTeam())
            }
            .onDisappear {
                // Останавливаем локальный таймер
                stopDisplayTimer()
            }
            .onChange(of: appState.activeOperationsManager.currentOperationId) { newId in
                print("🔄 onChange: currentOperationId changed to \(newId?.uuidString ?? "nil")")
                // Обновляем контроллер при смене текущей операции
                updateControllerForCurrentOperation()
            }
            .fullScreenCover(isPresented: $showingSavedCommands) {
                SavedCommandsView(
                    onCommandSelected: { selectedCommand in
                        // Создаем новую параллельную операцию с выбранной командой
                        print("Selected command: \(selectedCommand.commandName)")
                        let operationData = CommandCreationController.convertCheckCommandToOperationData(selectedCommand)
                        print("Created operation data with commandName: \(operationData.commandName ?? "nil")")
                        let workData = OperationWorkController.createInitialWorkData(from: operationData)
                        appState.activeOperationsManager.addActiveOperation(workData)
                        // Автоматически переключаемся на новую операцию
                        appState.activeOperationsManager.switchToOperation(withId: workData.id)
                        print("Added new operation to manager and switched to it. Total operations: \(appState.activeOperationsManager.activeOperations.count)")
                        // Небольшая задержка перед закрытием для обновления view
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingSavedCommands = false
                        }
                    },
                    onCreateNewCommand: {
                        showingSavedCommands = false
                        showingCreateCommand = true
                    }
                )
                .environmentObject(appState)
                .id(sheetId)
            }
            .fullScreenCover(isPresented: $showingActiveOperations) {
                ActiveOperationsView(onOperationSelected: { selectedOperation in
                    print("🎯 Selected operation from ActiveOperationsView: \(selectedOperation.operationData.commandName ?? selectedOperation.operationData.operationType.displayName)")
                    // Переключаемся на выбранную активную операцию
                    appState.activeOperationsManager.switchToOperation(withId: selectedOperation.id)
                    // Обновляем контроллер сразу после переключения
                    updateControllerForCurrentOperation()
                    showingActiveOperations = false
                })
                .environmentObject(appState)
                .id(sheetId)
            }
            .fullScreenCover(isPresented: $showingCreateCommand) {
                CreateCommandView { newCommand in
                    showingCreateCommand = false
                    // После создания команды, автоматически создаем новую операцию
                    let operationData = CommandCreationController.convertCheckCommandToOperationData(newCommand)
                    let workData = OperationWorkController.createInitialWorkData(from: operationData)
                    appState.activeOperationsManager.addActiveOperation(workData)
                    // Автоматически переключаемся на новую операцию
                    appState.activeOperationsManager.switchToOperation(withId: workData.id)
                }
                .environmentObject(appState)
                .id(sheetId)
            }
        }

    var buttonTitle: String {
            if !controller.workData.hasFoundFireSource {
                return "Осередок пожежі знайдено"
            } else if !controller.workData.isWorkingInDangerZone {
                return "Почати роботу в осередку пожежі"
            } else if !controller.workData.isExitingDangerZone {
                return "Почати вихід ланки"
            } else {
                return "Вихід: заповнити журнал"
            }
        }
        
        var buttonDisabled: Bool {
            if !controller.workData.hasFoundFireSource {
                return false
            } else if !controller.workData.isWorkingInDangerZone {
                // Кнопка "Почати роботу в осередку пожежі" всегда активна
                return false
            } else {
                return false
            }
        }
        
        var buttonColor: Color {
            return buttonDisabled ? Color.gray : Color.blue
        }
}

    
    #Preview {
        let appState = AppState()
        let operationData = OperationData()
        let workData = OperationWorkData(operationData: operationData)
        appState.activeOperationsManager.addActiveOperation(workData)

        return OperationWorkView(onSave: { command in
            print("Saved command: \(command.commandName)")
        }, appState: appState)
        .environment(\.locale, Locale(identifier: "uk"))
    }

