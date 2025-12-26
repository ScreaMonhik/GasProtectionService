//
//  QRScannerView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct QRScannerView: View {
    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "qrcode.viewfinder")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green.opacity(0.7))

            Text("QR-сканер")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.top, 16)

            Text("Функціонал буде додано пізніше")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)

            Spacer()
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    QRScannerView()
}

