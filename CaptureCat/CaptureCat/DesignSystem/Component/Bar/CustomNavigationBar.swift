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
    let color: Color
    
    init(title: String, onBack: @escaping () -> Void, actionTitle: String? = nil, onAction: (() -> Void)? = nil, isSaveEnabled: Bool = false, color: Color = .black) {
        self.title = title
        self.onBack = onBack
        self.actionTitle = actionTitle
        self.onAction = onAction
        self.isSaveEnabled = isSaveEnabled
        self.color = color
    }

    var body: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(color)
                }
                
                Text(title)
                    .CFont(.headline03Bold)
                    .foregroundColor(color)

                Spacer()

                if let onAction, let actionTitle {
                    Button(actionTitle, action: onAction)
                        .primaryTextStyle(isEnabled: isSaveEnabled)
                        .disabled(!isSaveEnabled)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }
}
