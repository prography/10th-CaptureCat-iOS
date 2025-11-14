//
//  MenuRow.swift
//  CaptureCat
//
//  Created by minsong kim on 10/9/25.
//

import SwiftUI

struct MenuRow: View {
    let icon: Image
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon
                    .foregroundStyle(.text02)
                    .CFont(.subhead01Bold)
                    .frame(width: 24, height: 24, alignment: .center)

                Text(title)
                    .CFont(.subhead01Bold)
                    .foregroundStyle(.text02)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 20)
            .frame(height: 60)
        }
        .buttonStyle(.plain)
    }
}
