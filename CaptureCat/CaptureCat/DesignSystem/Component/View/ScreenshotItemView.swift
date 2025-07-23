//
//  ScreenshotItemView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/21/25.
//

import SwiftUI

struct ScreenshotItemView<Overlay: View>: View {
    @ObservedObject var viewModel: ScreenshotItemViewModel
    var cornerRadius: CGFloat
    private let overlay: () -> Overlay
    
    init(viewModel: ScreenshotItemViewModel,
         cornerRadius: CGFloat = 12,
         @ViewBuilder overlay: @escaping () -> Overlay) {
        self.viewModel = viewModel
        self.cornerRadius = cornerRadius
        self.overlay = overlay
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                // ✅ thumbnail 우선, 없으면 fullImage 사용
                if let img = viewModel.thumbnail ?? viewModel.fullImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if viewModel.isLoadingImage {
                    ProgressView()
                        .frame(minHeight: 100)
                } else {
                    // 이미지 로드 실패 시 플레이스홀더
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(minHeight: 100)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .border(.overlayDim, width: 1)
            
            overlay()
                .padding(6)
        }
    }
}
