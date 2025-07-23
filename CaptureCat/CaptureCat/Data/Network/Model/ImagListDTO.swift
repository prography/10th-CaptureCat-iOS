//
//  ImagListDTO.swift
//  CaptureCat
//
//  Created by minsong kim on 7/23/25.
//

import Foundation

// MARK: - Welcome
struct ImagListDTO: Decodable {
    let result: String
    let data: DataClass
}

// MARK: - DataClass
struct DataClass: Decodable {
    let hasNext: Bool
    let lastCursor: Int?  // nullable 처리
    let items: [Item]
}

// MARK: - Item
struct Item: Decodable {
    let id: Int
    let name: String
    let url: String
    let captureDate: String
    let isBookmarked: Bool
    let tags: [Tag]
}

// MARK: - Tag
struct Tag: Decodable {
    let id: Int
    let name: String
}
