//
//  PastelMeshView.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 24.02.2026.
//

import SwiftUI


struct PastelMeshView: View {
    @State private var appear = false
    
    // Цвета в пастельной гамме
    let colors: [Color] = [
        .init(red: 0.8, green: 0.9, blue: 1.0), // Нежно-голубой
        .init(red: 0.9, green: 0.8, blue: 1.0), // Лавандовый
        .init(red: 1.0, green: 0.8, blue: 0.9), // Розовый кварц
        .init(red: 0.8, green: 1.0, blue: 0.9), // Мятный
        .init(red: 1.0, green: 0.9, blue: 0.8), // Персиковый
        .init(red: 0.9, green: 1.0, blue: 1.0)  // Светло-бирюзовый
    ]

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                // Верхний ряд
                [0, 0], [appear ? 0.5 : 0.4, 0], [1, 0],
                // Средний ряд (анимируем эти точки для движения)
                [0, 0.5], [appear ? 0.8 : 0.2, appear ? 0.2 : 0.8], [1, 0.5],
                // Нижний ряд
                [0, 1], [appear ? 0.4 : 0.6, 1], [1, 1]
            ],
            colors: colors.shuffled() // Перемешиваем для мягкости
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                appear.toggle()
            }
        }
    }
}

#Preview {
  PastelMeshView()
}
