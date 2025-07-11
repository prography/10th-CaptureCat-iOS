//
//  BottomSheet.swift
//  CaptureCat
//
//  Created by minsong kim on 7/6/25.
//

import Combine
import SwiftUI

// MARK: - BottomSheetModifier with Dynamic Height
struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: () -> SheetContent
    
    @State private var contentHeight: CGFloat = .zero
    @State private var offsetY: CGFloat = .zero
    @State private var keyboardHeight: CGFloat = 0
    @State private var cancellables = Set<AnyCancellable>()
    
    func body(content: Content) -> some View {
        let stack = ZStack(alignment: .bottom) {
            // 메인 콘텐츠
            content
                .disabled(isPresented)
                .blur(radius: isPresented ? 2 : 0)
            
            // Dimmed background
            if isPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }
                    .transition(.opacity)
                
                sheetView()
                    .ignoresSafeArea()
                    .offset(y: offsetY - keyboardHeight)
                    .transition(.move(edge: .bottom))
            }
        }
            .animation(.easeInOut, value: isPresented)
            .onAppear(perform: setupKeyboardObservers)
        
        return Group {
            if isPresented {
                stack.ignoresSafeArea(edges: .bottom)
            } else {
                stack
            }
        }
    }
    
    @ViewBuilder
    private func sheetView() -> some View {
        VStack(spacing: 0) {
            // 실제 컨텐츠: 높이 측정을 위해 GeometryReader + Preference 사용
            sheetContent()
                .padding(.horizontal)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: HeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
            // 측정된 높이를 저장
                .onPreferenceChange(HeightPreferenceKey.self) { h in
                    contentHeight = h + 50 // padding 보정
                }
        }
        .frame(height: contentHeight)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
        )
        .offset(y: offsetY)
        .gesture(dragGesture)
        .onAppear { show() }
    }
    
    // 드래그로 내리기
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gestureState in
                if gestureState.translation.height > 0 {
                    offsetY = gestureState.translation.height
                }
            }
            .onEnded { gestureState in
                if gestureState.translation.height > contentHeight * 0.3 {
                    dismiss()
                } else {
                    withAnimation(.spring()) { offsetY = 0 }
                }
            }
    }
    
    // 보여주기 애니메이션
    private func show() {
        offsetY = contentHeight
        withAnimation(.spring()) {
            offsetY = 0
        }
    }
    // 닫기 처리
    private func dismiss() {
        withAnimation(.spring()) {
            offsetY = contentHeight
            isPresented = false
        }
    }
    
    private func setupKeyboardObservers() {
        // 키보드 올라올 때
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .sink { height in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = height - 180
                }
            }
            .store(in: &cancellables)
        
        // 키보드 내려갈 때
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }
            .store(in: &cancellables)
    }
}
