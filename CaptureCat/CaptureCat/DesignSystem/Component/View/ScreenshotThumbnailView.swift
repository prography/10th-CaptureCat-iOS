//
//  ScreenshotThumbnailView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI
import Photos

struct ScreenshotThumbnailView: View {
    @State private var image: UIImage? = nil
    
    let asset: PHAsset
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(45 / 76, contentMode: .fill)
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
