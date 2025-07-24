//
//  Screenshot.swift
//  CaptureCat
//
//  Created by minsong kim on 7/14/25.
//

import Foundation
import SwiftData

@Model
final class Screenshot {
    @Attribute(.unique) var id: String = UUID().uuidString
    var fileName: String = ""
    var createDate: String = ""
    // 실제 저장되는 컬럼
      var tagsJSON: String = "[]"

      // 편의 속성(코드에서만 쓰는)
      var tags: [String] {
        get {
          (try? JSONDecoder().decode([String].self, from: Data(tagsJSON.utf8))) ?? []
        }
        set {
          tagsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
      }
    var isFavorite: Bool = false
    
    init(id: String,
         fileName: String,
         createDate: String,
         tags: [String] = [],
         isFavorite: Bool = false) {
        self.id = id
        self.fileName = fileName
        self.createDate = createDate
        self.tags = tags
        self.isFavorite = isFavorite
    }
}
