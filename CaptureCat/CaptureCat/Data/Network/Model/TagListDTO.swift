//
//  TagListDTO.swift
//  CaptureCat
//
//  Created by minsong kim on 8/6/25.
//

import Foundation

struct TagListDTO: Decodable {
    let result: String
    let data: [Tag]
}
