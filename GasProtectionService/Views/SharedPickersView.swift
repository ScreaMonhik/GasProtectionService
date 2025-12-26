//
//  SharedPickersView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 26.12.2025.
//

import SwiftUI

// MARK: - Device Picker View
struct DevicePickerView: View {
    @Binding var selectedDevice: DeviceType
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List(DeviceType.allCases, id: \.self) { device in
                Button(action: {
                    selectedDevice = device
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(device.displayName)
                        Spacer()
                        if selectedDevice == device {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Оберіть тип апарату")
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    DevicePickerView(selectedDevice: .constant(.dragerPSS3000))
}
