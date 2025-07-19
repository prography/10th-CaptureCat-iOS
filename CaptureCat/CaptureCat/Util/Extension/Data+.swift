//
//  Data+.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

extension Data {
    /// Data를 SwiftUI Image로 변환. 실패 시 placeholder(Color.gray)로 대체.
    func toImage(width: CGFloat = 45, height: CGFloat = 76, contentMode: ContentMode = .fill) -> some View {
        Group {
            if let uiImage = UIImage(data: self) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(width / height, contentMode: contentMode)
            } else {
                Color.gray
            }
        }
    }
}
