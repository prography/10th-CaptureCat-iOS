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
        backgroundRotation: Angle = .degrees(-10),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.backgroundOffset = backgroundOffset
        self.backgroundRotation = backgroundRotation
    }
    
    var body: some View {
        ZStack {
            // 뒤 레이어
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backLayerStyle)
                .rotationEffect(backgroundRotation)
            
            // 앞쪽 카드
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)
                .overlay(
                    content
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
        }
        .compositingGroup() // 회전·오프셋 시 레이어 합성 품질 향상
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
