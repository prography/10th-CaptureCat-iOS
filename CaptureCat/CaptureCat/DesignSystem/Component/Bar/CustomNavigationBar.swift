//
//  CustomRouterBar.swift
//  CaptureCat
//
//  Created by minsong kim on 6/30/25.
//

import SwiftUI

struct CustomNavigationBar: View {
    let title: String
    let onBack: () -> Void
    let actionTitle: String?
    let onAction: (() -> Void)?
    let isSaveEnabled: Bool

    private let enabledColor: Color   = .primary01
    private let disabledColor: Color  = .gray04
    private let enabledFont: CFont    = .subhead01Bold
    private let disabledFont: CFont   = .body01Regular

    var body: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
                
                Text(title)
                    .CFont(.headline03Bold)
                    .foregroundColor(.text01)

                Spacer()

                if let onAction, let actionTitle {
                    Button(actionTitle, action: onAction)
                        .buttonStyle(
                            PrimaryTextButtonStyle(
                                isEnabled: isSaveEnabled,
                                enabledColor: enabledColor,
                                disabledColor: disabledColor,
                                enabledFont: enabledFont,
                                disabledFont: disabledFont
                            )
                        )
                        .disabled(!isSaveEnabled)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
        .padding(.bottom, 10)
    }
}
