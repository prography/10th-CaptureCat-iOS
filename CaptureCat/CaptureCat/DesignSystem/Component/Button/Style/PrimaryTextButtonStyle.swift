//
//  PrimaryTextButtonStyle.swift
//  CaptureCat
//
//  Created by minsong kim on 7/1/25.
//

import SwiftUI

struct PrimaryTextButtonStyle: ButtonStyle {
    var isEnabled: Bool
    let enabledColor: Color
    let disabledColor: Color
    let enabledFont: CFont
    let disabledFont: CFont
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .foregroundColor(isEnabled ? enabledColor : disabledColor)
            .CFont(isEnabled ? enabledFont : disabledFont)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
