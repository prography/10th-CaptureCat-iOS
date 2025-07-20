//
//  MultipartFile.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import Foundation

// multipart/form-data용 파일 정보를 담는 구조체
struct MultipartFile {
    let filename: String    // 서버에 전달할 파일명
    let mimeType: String    // 예: "image/jpeg"
    let data: Data          // 실제 파일 바이트
}
