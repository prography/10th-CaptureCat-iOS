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
                        withAnimation {
                            isPresented = false
                        }
                    }
                
                VStack(spacing: 16) {
                    Text(title)
                        .CFont(.headline02Bold)
                        .foregroundStyle(.text01)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(message)
                        .CFont(.body02Regular)
                        .foregroundStyle(.text01)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            withAnimation { isPresented = false }
                        }) {
                            Text(cancelTitle)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.primaryLow)
                                .foregroundStyle(.primary01)
                                .cornerRadius(6)
                                .CFont(.subhead01Bold)
                        }
                        
                        Button(action: {
                            withAnimation { isPresented = false }
                            confirmAction()
                        }) {
                            Text(confirmTitle)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
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
                .frame(maxWidth: 300)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
