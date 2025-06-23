//
//  Button+.swift
//  CaptureCat
//
//  Created by minsong kim on 6/23/25.
//

import SwiftUI

extension Button {
    func chipStyle(
        isSelected: Bool,
        selectedBackground: Color = .gray09,
        selectedForeground: Color = .white,
        unselectedBackground: Color = .white,
        unselectedForeground: Color = .gray09,
        borderColor: Color? = .gray09,
        icon: Image? = nil
    ) -> some View {
        buttonStyle(
            ChipButtonStyle(
                isSelected: isSelected,
                selectedBackground: selectedBackground,
                selectedForeground: selectedForeground,
                unselectedBackground: unselectedBackground,
                unselectedForeground: unselectedForeground,
                borderColor: borderColor,
                icon: icon
            )
        )
    }
    
    func primaryStyle(
        cornerRadius: CGFloat = 8,
        backgroundColor: Color = .primary01,
        foregroundColor: Color = .white,
        verticalPadding: CGFloat = 14
    ) -> some View {
        self.buttonStyle(
            PrimaryButtonStyle(
                cornerRadius: cornerRadius,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                verticalPadding: verticalPadding
            )
        )
    }
}
