//
//  ToastModifier.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let textColor: Color
    let duration: TimeInterval
    let fillWidth: Bool
    let cornerRadius: CGFloat
    let isCenter: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: isCenter ? .center : .bottom) {
                if isShowing {
                    Text(message)
                        .CFont(.subhead02Bold)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .frame(height: 46)
                        .frame(maxWidth: fillWidth ? .infinity : nil)
                        .padding(.horizontal, 16)
                        .background(.secondary01)
                        .cornerRadius(cornerRadius)
                        .padding(.bottom, isCenter ? 0 : 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onChange(of: isShowing) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
    }
}
