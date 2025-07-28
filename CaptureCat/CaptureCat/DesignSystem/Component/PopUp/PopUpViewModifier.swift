//
//  PopUpViewModifier.swift
//  CaptureCat
//
//  Created by minsong kim on 6/23/25.
//

import SwiftUI

struct PopUpViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let confirmAction: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                Color.overlayDim
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                VStack(alignment: .center, spacing: 16) {
                    Text(title)
                        .CFont(.headline02Bold)
                        .foregroundStyle(.text01)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Text(message)
                        .CFont(.body02Regular)
                        .foregroundStyle(.text01)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Text(cancelTitle)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(Color.gray02)
                                .foregroundStyle(.text03)
                                .cornerRadius(6)
                                .CFont(.subhead01Bold)
                        }
                        
                        Button(action: {
                            isPresented = false
                            confirmAction()
                        }) {
                            Text(confirmTitle)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(Color.primary01)
                                .foregroundStyle(.white)
                                .cornerRadius(6)
                                .CFont(.subhead01Bold)
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
