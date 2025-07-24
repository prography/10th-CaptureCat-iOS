//
//  ImageDTO.swift
//  CaptureCat
//
//  Created by minsong kim on 7/23/25.
//

import Foundation

// MARK: - Welcome
struct ImageDTO: Decodable {
    let result: String
    let data: ImageData
}

struct ImageData: Decodable {
    let id: Int
    let name: String
    let url: String
    let captureDate: String
    let isBookmarked: Bool
    let tags: [Tag]
}
