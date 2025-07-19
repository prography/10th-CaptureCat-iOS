//
//  MultiCardView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/2/25.
//

import SwiftUI

// 범용 카드 컨테이너
struct MultiCardView<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let backgroundOffset: CGFloat
    let backgroundRotation: Angle
    let backLayerStyle: AnyShapeStyle = AnyShapeStyle(
        LinearGradient(
            gradient: Gradient(colors: [Color.gradientStart, Color.gradientEnd]),
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    )
    
    init(
        cornerRadius: CGFloat = 24,
        backgroundOffset: CGFloat = 12,
        backgroundRotation: Angle = .degrees(-8),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.backgroundOffset = backgroundOffset
        self.backgroundRotation = backgroundRotation
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 뒤쪽 카드
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backLayerStyle)
                    .rotationEffect(backgroundRotation)
                    .offset(x: backgroundOffset, y: backgroundOffset)

                // 앞쪽 카드
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .overlay(
                        content
                            .frame(width: geo.size.width, height: geo.size.height) // ✅ 부모 크기에 맞춤
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    )
            }
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .aspectRatio(45 / 76, contentMode: .fit) // ✅ 원하는 비율 유지, 부모 레이아웃에 따라 자동 조절
    }
}
