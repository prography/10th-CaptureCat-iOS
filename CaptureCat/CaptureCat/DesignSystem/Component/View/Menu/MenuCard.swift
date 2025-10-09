//
//  MenuCard.swift
//  CaptureCat
//
//  Created by minsong kim on 10/9/25.
//

import SwiftUI

struct MenuCard: View {
    var uploadAction: () -> Void
    var organizeAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MenuRow(
                icon: Image(.upload),
                title: "캡처 업로드",
                action: uploadAction
            )
            MenuRow(
                icon: Image(.delete3),
                title: "캡처 정리",
                action: organizeAction
            )
        }
        .padding(.vertical, 12)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 10)
        )
    }
}
