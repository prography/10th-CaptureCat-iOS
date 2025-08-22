//
//  CustomRouterBar.swift
//  CaptureCat
//
//  Created by minsong kim on 6/30/25.
//

import SwiftUI

struct CustomNavigationBar: View {
    let title: LocalizedStringKey
    let onBack: () -> Void
    let actionTitle: LocalizedStringKey?
    let onAction: (() -> Void)?
    let isSaveEnabled: Bool
    let color: Color
    
    init(
        title: LocalizedStringKey,
        onBack: @escaping () -> Void,
        actionTitle: LocalizedStringKey? = nil,
        onAction: (() -> Void)? = nil,
        isSaveEnabled: Bool = false,
        color: Color = .text02
    ) {
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
                    .CFont(.headline02Bold)
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
