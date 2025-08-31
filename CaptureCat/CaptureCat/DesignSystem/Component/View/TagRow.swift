//
//  TagRow.swift
//  CaptureCat
//
//  Created by minsong kim on 8/22/25.
//

import SwiftUI

struct TagRow: View {
    let tag: Tag
    var onEdit: () -> Void
    
    var body: some View {
        HStack {
            Text(tag.name)                // 예: "추가된 태그"
                .CFont(.body01Regular)
                .foregroundStyle(.text01)
            
            Spacer()
            
            Button(action: onEdit) {
                Text("수정")
                    .CFont(.body01Regular)
                    .foregroundStyle(.gray05) // 옅은 회색 느낌
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 48) // 셀 높이
        .contentShape(Rectangle()) // 전체 영역 터치 가능
    }
}
