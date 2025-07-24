//
//  ScreenshotItem.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import Foundation
import Photos

/// Presentation / Domain 레이어에서 쓰이는 Value 타입 모델
struct ScreenshotItem: Identifiable, Equatable {
    let id: String                 // PHAsset.localIdentifier 또는 서버 ID
    var imageData: Data            // UI에서 바로 쓰기 위한 Data (썸네일/풀사이즈)
    var imageURL: String?          // 서버 이미지 URL (서버 데이터인 경우)
    var fileName: String
    var createDate: String
    var tags: [String]
    var isFavorite: Bool

    /// 일반 생성자 (로컬 로드 후 PhotoLoader로 이미지 불러오기 전용)
    init(
        id: String,
        imageData: Data = Data(),
        imageURL: String? = nil,
        fileName: String,
        createDate: String,
        tags: [String] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.imageData = imageData
        self.imageURL = imageURL
        self.fileName = fileName
        self.createDate = createDate
        self.tags = tags
        self.isFavorite = isFavorite
    }

    /// Persistence 엔티티 → ScreenshotItem
    init(entity: Screenshot) {
        self.id = entity.id
        self.imageData = Data()               // 실제 이미지는 PhotoLoader로 비동기 로드
        self.imageURL = nil                   // 로컬 데이터는 URL 없음
        self.fileName = entity.fileName
        self.createDate = entity.createDate
        self.tags = entity.tags
        self.isFavorite = entity.isFavorite
    }

    /// Network DTO → ScreenshotItem
    init(dto: PhotoDTO) {
        self.id = dto.id
        self.imageData = dto.imageData ?? Data()
        self.imageURL = nil                   // PhotoDTO는 로컬 업로드용
        self.fileName = dto.fileName
        self.createDate = dto.createDate
        self.tags = dto.tags
        self.isFavorite = dto.isFavorite
    }

    /// ScreenshotItem → Network DTO
    func toDTO() -> PhotoDTO {
        PhotoDTO(
            id: id,
            fileName: fileName,
            createDate: createDate,
            tags: tags,
            isFavorite: isFavorite,
            imageData: imageData
        )
    }
}

extension ScreenshotItem {
    /// PHAsset → ScreenshotItem 변환
    init(asset: PHAsset) {
        var dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
        // 1) ID, 생성일
        let id = asset.localIdentifier
        let createDate = dateFormatter.string(from: asset.creationDate ?? Date())
        // 2) 파일명 (원본 리소스에서 가져오기)
        let resources = PHAssetResource.assetResources(for: asset)
        let fileName = resources.first?.originalFilename ?? "Unknown.jpg"
        // 3) 기본값 태그/즐겨찾기
        self.init(
            id: id,
            imageData: Data(),        // 이미지 데이터는 PhotoLoader로 비동기 로드
            imageURL: nil,            // 로컬 PHAsset은 URL 없음
            fileName: fileName,
            createDate: createDate,
            tags: [],
            isFavorite: false
        )
    }
}
