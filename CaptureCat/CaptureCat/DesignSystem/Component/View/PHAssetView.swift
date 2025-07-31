//
//  PHAssetView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI
import Photos

struct PHAssetView: View {
    @State private var image: UIImage?
    
    let asset: PHAsset
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { proxy in
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
                        .clipped()
                } else {
                    Color(white: 0.9)
                        .onAppear { loadImage() }
                }
            }
            .clipped()
            
            Image(systemName: "checkmark.square.fill")
                .padding(6)
                .foregroundColor(.primary01)
                .opacity(isSelected ? 1 : 0.6)
            
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(45/76, contentMode: .fit)
        .clipped()
        .overlay(
            RoundedRectangle(cornerSize: .zero)
                .stroke(isSelected ? Color.primary01 : Color.clear, lineWidth: 2)
        )
    }
    
    private func loadImage() {
        let manager = PHCachingImageManager()
        
        manager.requestImage(
            for: asset,
            targetSize: .zero,
            contentMode: .aspectFill,
            options: nil
        ) { image, _ in
            self.image = image
        }
    }
}
