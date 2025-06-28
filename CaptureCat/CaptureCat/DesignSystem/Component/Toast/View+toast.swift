//
//  View+toast.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

extension View {
    func toast(isShowing: Binding<Bool>,
               message: String,
               textColor: Color = .white,
               duration: TimeInterval = 1) -> some View {
        self.modifier(
            ToastModifier(
                isShowing: isShowing,
                message: message,
                textColor: textColor,
                duration: duration
            )
        )
    }
}
