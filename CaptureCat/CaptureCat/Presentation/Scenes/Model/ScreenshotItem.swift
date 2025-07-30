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
    var tags: [Tag]  // Tag 타입으로 변경
    var isFavorite: Bool

    /// 일반 생성자 (로컬 로드 후 PhotoLoader로 이미지 불러오기 전용)
    init(
        id: String,
        imageData: Data = Data(),
        imageURL: String? = nil,
        fileName: String,
        createDate: String,
        tags: [Tag] = [],
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

    /// Persistence 엔티티 → ScreenshotItem (String 배열을 Tag 배열로 변환)
    init(entity: Screenshot) {
        self.id = entity.id
        self.imageData = Data()               // 실제 이미지는 PhotoLoader로 비동기 로드
        self.imageURL = nil                   // 로컬 데이터는 URL 없음
        self.fileName = entity.fileName
        self.createDate = entity.createDate
        // String 배열을 Tag 배열로 변환 (인덱스를 임의 ID로 사용)
        self.tags = entity.tags.enumerated().map { index, tagName in
            Tag(id: index, name: tagName)
        }
        self.isFavorite = entity.isFavorite
    }

    /// Network DTO → ScreenshotItem (네트워크 Tag를 SwiftData Tag로 변환)
    init(dto: PhotoDTO) {
        self.id = dto.id
        self.imageData = dto.imageData ?? Data()
        self.imageURL = nil                   // PhotoDTO는 로컬 업로드용
        self.fileName = dto.fileName
        self.createDate = dto.createDate
        // String 배열을 Tag 배열로 변환 (PhotoDTO의 tags가 [String]인 경우)
        self.tags = dto.tags.enumerated().map { index, tagName in
            Tag(id: index, name: tagName)  // 임시 ID 사용
        }
        self.isFavorite = dto.isFavorite
    }
    
    /// 서버 Item → ScreenshotItem (서버 Tag를 직접 사용)
    init(serverItem: Item) {
        self.id = String(serverItem.id)
        self.imageData = Data()
        self.imageURL = serverItem.url
        self.fileName = serverItem.name
        self.createDate = serverItem.captureDate
        // 서버 Tag를 직접 사용
        self.tags = serverItem.tags.map { serverTag in
            Tag(id: serverTag.id, name: serverTag.name)
        }
        self.isFavorite = serverItem.isBookmarked
    }
    
    /// 서버 ImageData → ScreenshotItem (서버 Tag를 직접 사용)
    init(serverImageData: ImageData) {
        self.id = String(serverImageData.id)
        self.imageData = Data()
        self.imageURL = serverImageData.url
        self.fileName = serverImageData.name
        self.createDate = serverImageData.captureDate
        // 서버 Tag를 직접 사용
        self.tags = serverImageData.tags.map { serverTag in
            Tag(id: serverTag.id, name: serverTag.name)
        }
        self.isFavorite = serverImageData.isBookmarked
    }
    
    /// 서버 FavoriteItem → ScreenshotItem (태그 정보 없음)
    init(favoriteItem: FavoriteItem) {
        self.id = String(favoriteItem.id)
        self.imageData = Data()
        self.imageURL = favoriteItem.url
        self.fileName = favoriteItem.name
        self.createDate = favoriteItem.captureDate
        self.tags = []  // FavoriteItem에는 tags 정보가 없음
        self.isFavorite = favoriteItem.isBookmarked
    }

    /// ScreenshotItem → Network DTO
    func toDTO() -> PhotoDTO {
        PhotoDTO(
            id: id,
            fileName: fileName,
            createDate: createDate,
            tags: tags.map { $0.name },  // Tag.name으로 접근
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
    
    /// Tag 배열을 String 배열로 변환 (SwiftData 저장용)
    func getTagNames() -> [String] {
        return tags.map { $0.name }
    }
}
