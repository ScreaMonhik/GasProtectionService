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
    var onSave: (CheckCommand) -> Void
    
    
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
            let workData = OperationWorkData(operationData: emptyData)
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
        displayExitTimer = currentOperation.exitTimer
        displayRemainingTimer = currentOperation.remainingTimer
        displayCommunicationTimer = currentOperation.communicationTimer
    }


    var body: some View {
        NavigationView {
                ScrollView {
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
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Очікуваний час виходу ланки:")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(controller.workData.expectedExitTime)
                                        .font(.body)
                                        .foregroundColor(.secondary)
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
                            
                            // Bottom Timers
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
                            }
                        }
                        .padding(.horizontal)
                        
                        // Danger Zone Start Block
                        if controller.workData.hasFoundFireSource {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Початок роботи в НДС")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(controller.workData.formattedFireSourceFoundTime)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Час пошуку очага")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(controller.workData.searchTime) хв")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Найменший тиск в ланці")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    TextField("Тиск", text: $controller.workData.lowestPressure)
                                        .frame(width: 80)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .disabled(controller.workData.isWorkingInDangerZone)
                                        .opacity(controller.workData.isWorkingInDangerZone ? 0.5 : 1.0)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Exit Start Block
                        if controller.workData.isWorkingInDangerZone {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Час початку виходу з НДС")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(controller.workData.formattedExitTime)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Тиск початку виходу з НДС")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(controller.workData.calculatedExitStartPressure)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        
                        // Exit Data Block
                        if controller.workData.isExitingDangerZone {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Час виходу з НДС")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(controller.workData.formattedExitTime)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Мінімальний тиск:")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    TextField("Тиск", text: $controller.workData.minimumExitPressure)
                                        .frame(width: 80)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                HStack {
                                    Text("Швидкість розходу")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(controller.workData.consumptionRate)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
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
                    .hideKeyboardOnTapAndSwipe()
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
                        let workData = OperationWorkData(operationData: operationData)
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
                    let workData = OperationWorkData(operationData: operationData)
                    appState.activeOperationsManager.addActiveOperation(workData)
                    // Автоматически переключаемся на новую операцию
                    appState.activeOperationsManager.switchToOperation(withId: workData.id)
                }
                .environmentObject(appState)
                .id(sheetId)
            }
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
                // Кнопка "Почати роботу в осередку пожежі" неактивна, пока не введен lowestPressure
                return controller.workData.lowestPressure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            } else {
                return false
            }
        }
        
        var buttonColor: Color {
            return buttonDisabled ? Color.gray : Color.blue
        }
    }
    
    // MARK: - Address Input View
    struct AddressInputView: View {
        @ObservedObject var locationService: LocationService
        var onSave: () -> Void
        var onCancel: () -> Void
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Адреса роботи ланки:")
                        .font(.headline)
                        .padding(.top)

                    HStack(spacing: 12) {
                        TextField("Введіть адресу роботи", text: $locationService.currentAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        Button(action: {
                            locationService.requestCurrentLocation()
                        }) {
                            ZStack {
                                if locationService.isLoadingLocation {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                } else {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(width: 44, height: 44)
                        }
                        .disabled(locationService.isLoadingLocation)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .hideKeyboardOnTapAndSwipe()
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Скасувати") {
                        onCancel()
                    },
                    trailing: Button("ОК") {
                        onSave()
                    }
                        .disabled(locationService.currentAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                )
            }
        }
    }
    
    // MARK: - Team Info View
    struct TeamInfoView: View {
        let members: [OperationMember]
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                List(members) { member in
                    HStack {
                        Image(systemName: member.role.iconName)
                            .foregroundColor(
                                member.role.iconColor == "systemOrange" ? .orange :
                                    member.role.iconColor == "systemRed" ? .red :
                                    member.role.iconColor == "systemGreen" ? .green : .gray
                            )
                            .frame(width: 30, height: 30)
                        
                        VStack(alignment: .leading) {
                            Text(member.fullName)
                                .font(.body)
                            Text(member.role.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(member.pressure) бар")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Члени ланки")
                .navigationBarItems(trailing: Button("Готово") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
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

