//
//  PhotoDTO.swift
//  CaptureCat
//
//  Created by minsong kim on 7/23/25.
//

import Foundation

struct PhotoDTO: Codable, Identifiable {
  let id: String
  var fileName: String
  var createDate: Date  // ✅ Date 타입 유지 (UploadImageBuilder에서 String으로 변환)
  var tags: [String]
  var isFavorite: Bool
  var imageData: Data?
}
