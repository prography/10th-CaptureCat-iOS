//
//  ScreenshotView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct ScreenshotView: View {
    @Binding var item: ScreenshotItemViewModel
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                Image(uiImage: item.fullImage ?? .apple)
            }
            .clipped()
            
            // 2. 왼쪽 하단에 태그들 표시
            HStack(spacing: 4) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .CFont(.caption01Semibold)
                        .padding(.horizontal, 7.5)
                        .padding(.vertical, 4.5)
                        .background(Color.overlayDim)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            .padding(6)
        }
    }
}
