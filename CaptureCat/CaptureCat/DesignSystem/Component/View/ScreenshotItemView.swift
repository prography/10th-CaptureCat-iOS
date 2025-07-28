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
         cornerRadius: CGFloat = 8,
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
                } else if viewModel.isLoadingImage {
                    ProgressView()
                } else {
                    // 이미지 로드 실패 시 플레이스홀더
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.overlayDim, lineWidth: 1)
            )
            
            overlay()
                .padding(6)
        }
        .aspectRatio(45/76, contentMode: .fit)
        .clipped()
        .onAppear {
            // ✅ 각 뷰가 나타날 때 개별적으로 썸네일 로드
            loadImageIfNeeded()
        }
    }
    
    // MARK: - Private Methods
    
    /// 이미지가 필요한 경우에만 로드 (중복 로드 방지)
    private func loadImageIfNeeded() {
        // 이미 이미지가 있거나 로딩 중인 경우 스킵
        guard viewModel.thumbnail == nil && 
              viewModel.fullImage == nil && 
              !viewModel.isLoadingImage else { return }
        
        Task {
            // 썸네일 크기로 이미지 로드 (더 빠름)
            await viewModel.loadThumbnail(size: CGSize(width: 150, height: 250))
        }
    }
}
