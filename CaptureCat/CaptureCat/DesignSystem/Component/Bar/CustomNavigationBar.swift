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
                        .primaryTextStyle(isEnabled: isSaveEnabled)
                        .disabled(!isSaveEnabled)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }
}
