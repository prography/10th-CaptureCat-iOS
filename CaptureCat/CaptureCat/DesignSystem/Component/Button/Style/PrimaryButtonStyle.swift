//
//  PrimaryButtonStyle.swift
//  CaptureCat
//
//  Created by minsong kim on 6/23/25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let verticalPadding: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .CFont(.subhead01Bold)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
