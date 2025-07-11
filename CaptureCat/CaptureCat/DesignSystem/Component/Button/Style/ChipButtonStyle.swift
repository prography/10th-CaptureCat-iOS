//
//  ChipButtonStyle.swift
//  CaptureCat
//
//  Created by minsong kim on 6/23/25.
//

import SwiftUI

struct ChipButtonStyle: ButtonStyle {
    let isSelected: Bool
    let selectedBackground: Color
    let selectedForeground: Color
    let unselectedBackground: Color
    let unselectedForeground: Color
    let selectedBorderColor: Color?
    let unselectedBorderColor: Color?
    let icon: Image?
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: icon == nil ? 0 : 6) {
            configuration.label
                .CFont(isSelected ? .subhead02Bold : .body02Regular)
            if let icon {
                icon
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .foregroundColor(isSelected ? selectedForeground : unselectedForeground)
        .background(
            Group {
                if isSelected {
                    selectedBackground
                } else {
                    unselectedBackground
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    (isSelected ? selectedBorderColor : unselectedBorderColor) ?? (isSelected ? selectedBackground : unselectedBackground),
                    lineWidth: 1.5
                )
        )
        .cornerRadius(20)
        .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
