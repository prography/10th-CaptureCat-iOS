//
//  PHAssetImageModifier.swift
//  CaptureCat
//
//  Created by minsong kim on 7/14/25.
//

import SwiftUI
import Photos

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
