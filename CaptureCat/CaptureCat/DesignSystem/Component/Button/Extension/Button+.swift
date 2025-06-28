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
        selectedBorderColor: Color? = nil,
        unselectedBorderColor: Color? = .gray04,
        icon: Image? = nil
    ) -> some View {
        buttonStyle(
            ChipButtonStyle(
                isSelected: isSelected,
                selectedBackground: selectedBackground,
                selectedForeground: selectedForeground,
                unselectedBackground: unselectedBackground,
                unselectedForeground: unselectedForeground,
                selectedBorderColor: selectedBorderColor,
                unselectedBorderColor: unselectedBorderColor,
                icon: icon
            )
        )
    }
    
    func primaryStyle(
        cornerRadius: CGFloat = 4,
        backgroundColor: Color = .primary01,
        foregroundColor: Color = .white,
        verticalPadding: CGFloat = 14,
        fillWidth: Bool = true
    ) -> some View {
        self.buttonStyle(
            PrimaryButtonStyle(
                cornerRadius: cornerRadius,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                verticalPadding: verticalPadding,
                fillWidth: fillWidth
            )
        )
    }
}
