//
//  JournalView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct JournalView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            if appState.checkController.journalCommands.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .resizable()
                        .frame(width: 80, height: 60)
                        .foregroundColor(.blue.opacity(0.7))

                    Text("Немає записів в журналі")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(appState.checkController.journalCommands) { command in
                            JournalCommandCard(command: command)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Journal Command Card
struct JournalCommandCard: View {
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


#Preview {
    JournalView()
}
