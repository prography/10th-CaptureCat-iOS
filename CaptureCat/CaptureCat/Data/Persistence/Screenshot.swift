//
//  Screenshot.swift
//  CaptureCat
//
//  Created by minsong kim on 7/14/25.
//

import Foundation
import SwiftData
import Photos

struct Tag: Codable {
  let value: String
}

@Model
final class Screenshot {
    @Attribute(.unique) var id: String = UUID().uuidString
    var fileName: String = ""
    var createDate: Date = Date()
//    @Attribute(.transformable(by: NSSecureUnarchiveFromDataTransformer.self))
    var tags: [Tag]
    var isFavorite: Bool = false
    
    init(id: String,
         fileName: String,
         createDate: Date,
         tags: [String] = [],
         isFavorite: Bool = false) {
        self.id = id
        self.fileName = fileName
        self.createDate = createDate
        self.tags = tags.compactMap { Tag(value: $0) }
        self.isFavorite = isFavorite
    }
}
