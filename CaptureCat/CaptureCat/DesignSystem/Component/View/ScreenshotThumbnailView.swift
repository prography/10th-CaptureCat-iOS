//
//  ScreenshotThumbnailView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI
import Photos

struct ScreenshotThumbnailView: View {
    @StateObject var item: ScreenshotItemViewModel
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let image = item.fullImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(45 / 76, contentMode: .fill)
                } else {
                    Color(white: 0.9)
                }
            }
            .clipped()
            
            Image(systemName: "checkmark.square.fill")
                .padding(6)
                .foregroundColor(.primary01)
                .opacity(isSelected ? 1 : 0.6)
            
        }
        .task {
            await item.loadFullImage()
        }
        .overlay(
            RoundedRectangle(cornerSize: .zero)
                .stroke(isSelected ? Color.primary01 : Color.clear, lineWidth: 2)
        )
    }
}
