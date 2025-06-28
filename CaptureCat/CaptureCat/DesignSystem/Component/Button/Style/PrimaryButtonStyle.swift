//
//  PrimaryButtonStyle.swift
//  CaptureCat
//
//  Created by minsong kim on 6/23/25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let verticalPadding: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        let background = isEnabled ? backgroundColor : Color.gray04
        let foreground = isEnabled ? foregroundColor : Color.gray08
        
        return configuration.label
            .CFont(.subhead01Bold)
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(background)
            .cornerRadius(cornerRadius)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
