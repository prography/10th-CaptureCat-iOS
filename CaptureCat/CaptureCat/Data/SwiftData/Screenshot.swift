//
//  Screenshot.swift
//  CaptureCat
//
//  Created by minsong kim on 7/14/25.
//

import Foundation
import SwiftData
import Photos

@Model
final class Screenshot {
    @Attribute(.unique) var fileName: String
    var isFavorite: Bool
    var tags: [String]
    
    init(fileName: String, isFavorite: Bool = false, tags: [String] = []) {
        self.fileName = fileName
        self.isFavorite = isFavorite
        self.tags = tags
    }
    
    // PHAsset으로부터 Screenshot 생성하는 편의 이니셜라이저
    convenience init(from asset: PHAsset, isFavorite: Bool, tags: [String] = []) {
        self.init(
            fileName: asset.localIdentifier,
            isFavorite: isFavorite,
            tags: tags
        )
    }
} 
