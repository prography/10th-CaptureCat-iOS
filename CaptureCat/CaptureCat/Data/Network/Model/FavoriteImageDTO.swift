//
//  FavoriteImageDTO.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

// MARK: - Welcome
struct FavoriteImageDTO: Decodable {
    let result: String
    let data: FavoriteData
}

// MARK: - DataClass
struct FavoriteData: Decodable {
    let hasNext: Bool
    let lastCursor: Int?  // nullable 처리
    let items: [FavoriteItem]
}

// MARK: - Item
struct FavoriteItem: Decodable {
    let id: Int
    let name: String
    let url: String
    let captureDate: String
    let isBookmarked: Bool
}
