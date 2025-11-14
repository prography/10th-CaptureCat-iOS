//
//  CustomLoadingView.swift
//  CaptureCat
//
//  Created by minsong kim on 11/3/25.
//

import SwiftUI

struct CustomLoadingView: View {
    @State private var isAnimating = false

    var lineWidth: CGFloat = 2
    var size: CGFloat = 16
    var color: Color = .white

    var body: some View {
        Circle()
            .trim(from: 0.2, to: 1) // 원의 일부만 보이게
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
