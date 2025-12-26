//
//  Check1View.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct Check1View: View {
    @EnvironmentObject var appState: AppState
    @State private var commandToDelete: CheckCommand?
    @State private var commandToEdit: CheckCommand?
    @State private var isCreatingCommand = false

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
                    Image(systemName: "person.3.fill")
                        .resizable()
                        .frame(width: 80, height: 60)
                        .foregroundColor(.blue.opacity(0.7))

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
                            CommandCard(command: command,
                                       onEdit: {
                                           commandToEdit = command
                                       },
                                       onDelete: {
                                           commandToDelete = command
                                       })
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
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .alert(item: $commandToDelete) { command in
            Alert(
                title: Text("Підтвердження видалення"),
                message: Text("Ви впевнені що хочете видалити ланку \"\(command.commandName)\"?"),
                primaryButton: .destructive(Text("Так")) {
                    appState.checkController.deleteCommand(command)
                    commandToDelete = nil
                },
                secondaryButton: .cancel(Text("Ні")) {
                    commandToDelete = nil
                }
            )
        }
        .fullScreenCover(isPresented: $isCreatingCommand) {
            CreateCommandView { command in
                appState.checkController.addCommand(command)
                isCreatingCommand = false
            }
        }
        .fullScreenCover(item: $commandToEdit) { command in
            CreateCommandView(command: command) { updatedCommand in
                appState.checkController.updateCommand(updatedCommand)
            }
        }
    }
}

// MARK: - Command Card
struct CommandCard: View {
    let command: CheckCommand
    var onEdit: () -> Void
    var onDelete: () -> Void

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
            
//            // Date
//            Text(command.formattedDate)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//
//            // Device Type
//            HStack {
//                Spacer()
//                Text(command.deviceType.displayName)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }

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

            // Action Buttons
            HStack {
                Button(action: onEdit) {
                    Text("Редагувати")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                Spacer()

                Button(action: onDelete) {
                    Text("Видалити ланку")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }
}

#Preview {
    Check1View()
}

