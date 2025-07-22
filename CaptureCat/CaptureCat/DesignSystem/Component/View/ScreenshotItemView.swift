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
                if let img = viewModel.fullImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    ProgressView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .border(.overlayDim, width: 1)
            
            overlay()
                .padding(6)
        }
    }
}
