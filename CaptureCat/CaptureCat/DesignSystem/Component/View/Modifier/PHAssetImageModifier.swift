//
//  PHAssetImageView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/14/25.
//

import SwiftUI
import Photos

struct PHAssetImageView: View {
    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = true
    
    let asset: PHAsset?
    let targetSize: CGSize
    
    init(asset: PHAsset?, targetSize: CGSize? = nil) {
        self.asset = asset
        // 화면 크기에 맞는 고해상도 크기 계산
        if let targetSize = targetSize {
            self.targetSize = targetSize
        } else if let asset = asset {
            // 실제 asset 크기를 고려한 최적화된 크기 계산
            let screenScale = UIScreen.main.scale
            let screenWidth = UIScreen.main.bounds.width
            let maxDisplaySize = screenWidth * 0.8 * screenScale // 화면의 80% 크기
            
            // asset의 원본 크기 고려
            let assetWidth = CGFloat(asset.pixelWidth)
            let assetHeight = CGFloat(asset.pixelHeight)
            let assetAspectRatio = assetWidth / assetHeight
            
            let optimalSize: CGFloat
            if assetAspectRatio > 1 { // 가로가 더 긴 경우
                optimalSize = min(assetWidth, maxDisplaySize)
            } else { // 세로가 더 긴 경우
                optimalSize = min(assetHeight, maxDisplaySize)
            }
            
            self.targetSize = CGSize(width: optimalSize, height: optimalSize)
        } else {
            // asset가 없는 경우 기본 크기
            let screenScale = UIScreen.main.scale
            let defaultSize = 400 * screenScale
            self.targetSize = CGSize(width: defaultSize, height: defaultSize)
        }
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill() // 카드뷰에 맞게 채움
                    .clipped() // 넘치는 부분 잘라냄
            } else if isLoading {
                // 로딩 상태
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                    
                    ProgressView()
                        .scaleEffect(1.2)
                }
                .aspectRatio(45/76, contentMode: .fit) // 카드뷰 비율에 맞춤
            } else {
                // 이미지가 없는 경우 기본 이미지
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                    
                    Image(.accountCircle)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.gray.opacity(0.5))
                }
                .aspectRatio(45/76, contentMode: .fit) // 카드뷰 비율에 맞춤
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadImage()
        }
        .onChange(of: asset) { _, newAsset in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let asset = asset else {
            self.image = nil
            self.isLoading = false
            return
        }
        
        isLoading = true
        
        let manager = PHCachingImageManager()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true // iCloud 사진 지원
        options.version = .current // 편집된 버전 사용
        
        // 먼저 저해상도 이미지를 빠르게 로드
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFit,
            options: nil
        ) { [self] lowResImage, _ in
            DispatchQueue.main.async {
                if self.image == nil && lowResImage != nil {
                    self.image = lowResImage
                }
            }
        }
        
        // 그다음 고해상도 이미지 로드
        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { [self] highResImage, _ in
            DispatchQueue.main.async {
                if let highResImage = highResImage {
                    self.image = highResImage
                }
                self.isLoading = false
            }
        }
    }
} 

struct PHAssetImageModifier: ViewModifier {
    let asset: PHAsset
    @State private var image: UIImage? = nil

    func body(content: Content) -> some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                content
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        let manager = PHCachingImageManager()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none

        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { uiImage, _ in
            self.image = uiImage
        }
    }
}

extension View {
    func phAssetImage(asset: PHAsset) -> some View {
        self.modifier(PHAssetImageModifier(asset: asset))
    }
}
