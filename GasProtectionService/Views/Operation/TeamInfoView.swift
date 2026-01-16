//
//  TeamInfoView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 16.01.2026.
//

import SwiftUI

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
