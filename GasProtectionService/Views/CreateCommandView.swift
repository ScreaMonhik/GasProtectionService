//
//  CreateCommandView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct CreateCommandView: View {
    @StateObject private var controller: CommandCreationController
    @Environment(\.presentationMode) var presentationMode
    var onSave: (CheckCommand) -> Void
    
    init(command: CheckCommand? = nil, onSave: @escaping (CheckCommand) -> Void) {
        self.onSave = onSave
        _controller = StateObject(wrappedValue: CommandCreationController(command: command))
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Перевірка номер 1")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(controller.command.id != CheckCommand().id ? "Редагування ланки" : "Створення ланки")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                        
                        // Command Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Назва ланки:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Введіть назву ланки", text: $controller.command.commandName)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Device Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Тип апарату:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                controller.showingDevicePicker.toggle()
                            }) {
                                HStack {
                                    Text(controller.command.deviceType.displayName)
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
                        
                        // Team Members
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Члени ланки:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(controller.command.teamMembers.indices, id: \.self) { index in
                                TeamMemberRow(
                                    member: $controller.command.teamMembers[index],
                                    onRescueTap: {
                                        controller.toggleRescueDevice(for: index)
                                    },
                                    onDelete: {
                                        controller.removeTeamMember(at: index)
                                    },
                                    canDelete: controller.canRemoveMember(at: index)
                                )
                                .id(index) // Добавляем id для прокрутки
                            }
                        }
                        .padding(.horizontal)
                        
                        // Add Button
                        Button(action: {
                            controller.addTeamMember()
                            // Scroll to bottom of the page
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollView.scrollTo("bottom", anchor: .bottom)
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
                        
                    // Save Button
                    Button(action: {
                        if controller.isValidCommand() {
                            onSave(controller.command)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Text("Зберегти")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(controller.isValidCommand() ? Color.green : Color.gray)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(!controller.isValidCommand())
                    .id("bottom") // ID для прокрутки до низу
                    }
                    .padding(.bottom, 32)
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
            .sheet(isPresented: $controller.showingDevicePicker) {
                DevicePickerView(selectedDevice: $controller.command.deviceType)
            }
            .alert(isPresented: $controller.showingRescueAlert) {
                Alert(
                    title: Text("Рятівний пристрій"),
                    message: Text("Додати рятівний пристрій?"),
                    primaryButton: .default(Text("Так")) {
                        controller.setRescueDevice(hasDevice: true)
                    },
                    secondaryButton: .cancel(Text("Ні")) {
                        controller.setRescueDevice(hasDevice: false)
                    }
                )
            }
        }
    }
    
    // MARK: - Team Member Row
    struct TeamMemberRow: View {
        @Binding var member: TeamMember
        var onRescueTap: () -> Void
        var onDelete: () -> Void
        var canDelete: Bool

        var body: some View {
            HStack(spacing: 12) {
                // Rescue Device Icon
                Button(action: onRescueTap) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 24))
                        .foregroundColor(member.hasRescueDevice ? .blue : .gray.opacity(0.5))
                }
                .frame(width: 40, height: 40)

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
        }
    }
    
    
    #Preview {
        CreateCommandView { command in
            print("Saved command: \(command.commandName)")
        }
    }
}
