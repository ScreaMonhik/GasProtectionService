//
//  SideMenuView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 24.12.2025.
//

import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    let controller: SideMenuController

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Користувач")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("user@gdzs.ua")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                    Divider()
                }

                // Menu Items
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(controller.menuItems, id: \.id) { item in
                            MenuItemView(icon: item.icon, title: item.title) {
                                controller.handleMenuItemTap(item)
                                isShowing = false
                            }
                        }
                    }
                    .padding(.vertical)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shadow(radius: 5)
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    SideMenuView(isShowing: .constant(true), controller: SideMenuController())
}
