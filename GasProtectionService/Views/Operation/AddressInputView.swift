//
//  AddressInputView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 16.01.2026.
//

import SwiftUI

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
