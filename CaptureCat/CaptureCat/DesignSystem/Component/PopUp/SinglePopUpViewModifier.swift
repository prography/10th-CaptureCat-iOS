//
//  SinglePopUpViewModifier.swift
//  CaptureCat
//
//  Created by minsong kim on 6/29/25.
//

import SwiftUI

struct SinglePopUpViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    let title: String?
    let message: String
    let cancelTitle: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                Color.overlayDim
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                
                VStack(spacing: 16) {
                    if let title {
                        Text(title)
                            .CFont(.headline02Bold)
                            .foregroundStyle(.text01)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    Text(message)
                        .CFont(.body02Regular)
                        .foregroundStyle(.text01)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        withAnimation { isPresented = false }
                    }) {
                        Text(cancelTitle)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.primary01)
                            .foregroundStyle(.white)
                            .cornerRadius(6)
                            .CFont(.subhead01Bold)
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .frame(maxWidth: 300)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
