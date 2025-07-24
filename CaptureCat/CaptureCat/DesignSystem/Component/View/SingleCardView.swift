//
//  SingleCardView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/2/25.
//

import SwiftUI

// 범용 카드 컨테이너 - 삭제 애니메이션 적용을 위해 분리
struct SingleCardView<Content: View>: View {
    @State private var dragOffset: CGSize = .zero
    @State private var isDismissed = false
    
    let threshold: CGFloat = -150  // 이 값 이상으로 위로 밀면 사라짐
    let content: Content
    let cornerRadius: CGFloat
    let onDelete: (() -> Void)?  // 삭제 콜백 추가
    
    init(
        cornerRadius: CGFloat = 24,
        onDelete: (() -> Void)? = nil,  // 삭제 콜백 매개변수 추가
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)
                .overlay(
                    content
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
            
            if dragOffset.height < 0 {
                VStack {
                    Spacer()
                    // 하단 그라데이션
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .overlay(
                        VStack(spacing: 8) {
                            Image(.delete)
                            Text("삭제할래요")
                                .CFont(.headline03Bold)
                                .foregroundColor(.white)
                                .padding(.bottom, 24)
                        },
                        alignment: .bottom
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .opacity(Double(-dragOffset.height / 100).clamped(to: 0...1))
            }
        }
        .offset(y: dragOffset.height)
        .opacity(isDismissed ? 0 : 1)
        .animation(.easeOut, value: isDismissed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    guard abs(value.translation.height) > abs(value.translation.width) else { return }
                    // 오직 위 방향으로만
                    dragOffset.height = min(0, value.translation.height)
                }
                .onEnded { _ in
                    if dragOffset.height < threshold {
                        // 충분히 밀었다면 사라짐
                        isDismissed = true
                        // 삭제 콜백 호출
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDelete?()
                        }
                    } else {
                        // 아니면 원위치
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .aspectRatio(45 / 76, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
