//
//  UIApplication+Extensions.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
