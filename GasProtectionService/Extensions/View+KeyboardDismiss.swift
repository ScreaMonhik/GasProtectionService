//
//  View+KeyboardDismiss.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 30.12.2025.
//

import SwiftUI

extension View {
    /// Добавляет возможность скрытия клавиатуры при тапе на пустую область или свайпе вниз
    func hideKeyboardOnTapAndSwipe() -> some View {
        self
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        UIApplication.shared.endEditing()
                    }
            )
    }
}
