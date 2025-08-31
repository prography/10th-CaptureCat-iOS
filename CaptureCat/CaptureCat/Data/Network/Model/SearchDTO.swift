//
//  SearchDTO.swift
//  CaptureCat
//
//  Created by minsong kim on 8/31/25.
//

import Foundation

struct SearchDTO: Codable {
    let result: String
    let data: [DataType]
}

struct DataType: Codable {
    let id: Int
    let name: String
}
