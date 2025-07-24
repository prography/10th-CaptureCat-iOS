//
//  TagDTO.swift
//  CaptureCat
//
//  Created by minsong kim on 7/23/25.
//

import Foundation

// MARK: - Welcome
struct TagDTO: Decodable {
    let result: String
    let data: TagData
}

// MARK: - DataClass
struct TagData: Decodable {
    let hasNext: Bool
    let lastCursor: Int
    let items: [Tag]
}
