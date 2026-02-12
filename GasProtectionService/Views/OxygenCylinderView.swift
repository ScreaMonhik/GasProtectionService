//
//  OxygenCylinderView.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 16.01.2026.
//

import SwiftUI

struct OxygenCylinderView: View {
    let oxygenPercentage: Double // 0.0 to 1.0
    
    // Цвет баллона в зависимости от уровня кислорода
    private var cylinderColor: Color {
        if oxygenPercentage > 0.5 {
            return .green
        } else if oxygenPercentage > 0.25 {
            return .yellow
        } else if oxygenPercentage > 0.1 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        // 1. Оборачиваем всё в ZStack, чтобы наложить слои
        ZStack(alignment: .center) {
            
            // СЛОЙ 1: Картинка на фоне
            Image("draeger_harness")
                .resizable()
                .scaledToFit()
            
            // СЛОЙ 2: Твой код баллона
            // Добавил внешний GeometryReader, чтобы узнать размер картинки и сделать отступы в %
            GeometryReader { outerGeo in
                
                // === ТВОЙ ОРИГИНАЛЬНЫЙ КОД ВНУТРИ ===
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        // Фон - пустой баллон (тусклый)
                        cylinderShape
                            .fill(Color(.systemGray4).opacity(0.4))
                            .overlay(
                                cylinderShape
                                    .stroke(Color(.systemGray3), lineWidth: 2)
                            )
                        
                        // Заполнение - просто прямоугольник снизу с clipShape
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            cylinderColor.opacity(0.9),
                                            cylinderColor
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: geometry.size.height * max(0, min(1, oxygenPercentage)))
                        }
                        .clipShape(cylinderShape) // Обрезаем по форме баллона
                        .shadow(color: cylinderColor.opacity(0.3), radius: 4, x: 0, y: 0)
                        
                        // Процент кислорода (текст)
                        VStack {
                            Spacer()
                            Text("\(Int(oxygenPercentage * 100))%")
                                .font(.system(size: geometry.size.width * 0.4)) // Сделал шрифт адаптивным
                                .fontWeight(.bold)
                                .foregroundColor(oxygenPercentage > 0.5 ? .white : .primary)
                                .padding(.bottom, 8)
                        }
                    }
                }
                // === КОНЕЦ ТВОЕГО ОРИГИНАЛЬНОГО КОДА ===
                
                // === НАСТРОЙКИ ОТСТУПОВ ===
                // Я поставил 28% с боков. Это оптимально для Drager.
                .padding(.horizontal, outerGeo.size.width * 0.28)
                // Отступы сверху и снизу в процентах от высоты
                .padding(.vertical, outerGeo.size.height * 0.12)
                .padding(.bottom, outerGeo.size.height * 0.04)
            }
        }
        .scaleEffect(1.15)
        .offset(y: -25)
    }
    
    // Форма баллона с вентилем сверху
    private var cylinderShape: some Shape {
        CylinderShape()
    }
}

// Кастомная форма баллона
struct CylinderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Настройка ширины баллона
        let bodyWidthRatio: CGFloat = 0.75 // Чуть расширил сам баллон внутри рамки
        
        let valveHeight: CGFloat = rect.height * 0.05 // Высота вентиля
        let valveWidth: CGFloat = rect.width * 0.3 // Ширина вентиля (чуть шире)
        let bodyTop = valveHeight
        
        // Вентиль (верхняя узкая часть)
        let valveRect = CGRect(
            x: (rect.width - valveWidth) / 2,
            y: 0,
            width: valveWidth,
            height: valveHeight
        )
        path.addRoundedRect(in: valveRect, cornerSize: CGSize(width: 4, height: 4))
        
        // Основной корпус баллона (с закругленным низом)
        let actualBodyWidth = rect.width * bodyWidthRatio
        let bodyX = (rect.width - actualBodyWidth) / 2
        
        let bodyRect = CGRect(
            x: bodyX,
            y: bodyTop,
            width: actualBodyWidth,
            height: rect.height - bodyTop
        )
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: 20, height: 20))
        
        return path
    }
}

// Preview для тестирования
#Preview("Full Cylinder") {
    OxygenCylinderView(oxygenPercentage: 1.0)
        .frame(width: 180, height: 400) // Пример хорошего размера
        .padding()
}

#Preview("Half Cylinder") {
    OxygenCylinderView(oxygenPercentage: 0.5)
        .frame(width: 180, height: 400)
        .padding()
}

#Preview("Low Cylinder") {
    OxygenCylinderView(oxygenPercentage: 0.2)
        .frame(width: 180, height: 400)
        .padding()
}

#Preview("All Levels") {
    HStack(spacing: 20) {
        VStack {
            OxygenCylinderView(oxygenPercentage: 1.0)
                .frame(width: 80, height: 200)
            Text("100%")
                .font(.caption)
        }
        VStack {
            OxygenCylinderView(oxygenPercentage: 0.75)
                .frame(width: 80, height: 200)
            Text("75%")
                .font(.caption)
        }
        VStack {
            OxygenCylinderView(oxygenPercentage: 0.5)
                .frame(width: 80, height: 200)
            Text("50%")
                .font(.caption)
        }
        VStack {
            OxygenCylinderView(oxygenPercentage: 0.25)
                .frame(width: 80, height: 200)
            Text("25%")
                .font(.caption)
        }
        VStack {
            OxygenCylinderView(oxygenPercentage: 0.10)
                .frame(width: 80, height: 200)
            Text("10%")
                .font(.caption)
        }
    }
    .padding()
}

#Preview {
    OxygenCylinderView(oxygenPercentage: 1.0)
}
