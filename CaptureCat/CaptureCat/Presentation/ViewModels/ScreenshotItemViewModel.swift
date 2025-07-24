//
//  ScreenshotItemViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/20/25.
//

import SwiftUI
import UIKit

@MainActor
class ScreenshotItemViewModel: ObservableObject, Identifiable {
    // MARK: – Properties
    let id: String
    let imageURL: String?              // ✅ 서버 이미지 URL
    @Published var fileName: String
    @Published var createDate: String
    @Published var thumbnail: UIImage?
    @Published var fullImage: UIImage?
    @Published var isLoadingImage = false
    @Published var tags: [String]
    @Published var isFavorite: Bool
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    private var saveWorkItem: DispatchWorkItem?
    
    /// 이미지 소스 타입 구분
    var isServerImage: Bool {
        return imageURL != nil
    }
    
    // MARK: – Init
    init(model: ScreenshotItem) {
        self.id = model.id
        self.imageURL = model.imageURL    // ✅ 서버 URL 저장
        self.fileName   = model.fileName
        self.createDate = model.createDate
        self.tags       = model.tags
        self.isFavorite = model.isFavorite
    }
    
    // MARK: – Image Loading
    func loadThumbnail(size: CGSize) async {
        debugPrint("🔍 loadThumbnail 시작 - ID: \(id), 서버이미지: \(isServerImage)")
        
        isLoadingImage = true
        defer { isLoadingImage = false }
        
        if isServerImage {
            // 서버 URL에서 이미지 다운로드
            debugPrint("⭐️ 썸네일 다운로드 시작! URL: \(imageURL ?? "없음")")
            thumbnail = await downloadImageFromURL(size: size)
        } else {
            // 로컬 PHAsset에서 이미지 로드
            debugPrint("📱 로컬 PHAsset에서 썸네일 로드 시작 - ID: \(id)")
            thumbnail = await PhotoLoader.shared.requestImage(
                id: id,
                targetSize: size
            )
        }
        
        if thumbnail != nil {
            debugPrint("✅ 썸네일 로드 성공 - ID: \(id)")
        } else {
            debugPrint("❌ 썸네일 로드 실패 - ID: \(id)")
        }
    }
    
    func loadFullImage() async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        
        if isServerImage {
            // 서버 URL에서 풀사이즈 이미지 다운로드
            debugPrint("⭐️ 이미지 다운로드 시작!")
            fullImage = await downloadImageFromURL(size: nil)
        } else {
            // 로컬 PHAsset에서 풀사이즈 이미지 로드
            fullImage = await PhotoLoader.shared.requestFullImage(id: id)
        }
    }
    
    /// 서버 URL에서 이미지 다운로드
    private func downloadImageFromURL(size: CGSize?) async -> UIImage? {
        guard let imageURL = imageURL,
              let url = URL(string: imageURL) else {
            debugPrint("❌ 유효하지 않은 이미지 URL: \(imageURL ?? "nil")")
            return nil
        }
        
        do {
            debugPrint("🔄 이미지 다운로드 시작: \(url)")
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let image = UIImage(data: data) else {
                debugPrint("❌ 이미지 데이터 변환 실패")
                return nil
            }
            
            // 크기 조정이 필요한 경우 (썸네일)
            if let targetSize = size {
                let resizedImage = resizeImage(image, to: targetSize)
                debugPrint("✅ 썸네일 다운로드 완료: \(targetSize)")
                return resizedImage
            } else {
                debugPrint("✅ 풀사이즈 이미지 다운로드 완료")
                return image
            }
            
        } catch {
            debugPrint("❌ 이미지 다운로드 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 이미지 크기 조정 헬퍼
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: – User Actions
    func toggleFavorite() {
        // Repository를 통해 즐겨찾기 상태 토글 (자동 분기 처리)
        Task {
            do {
                try await ScreenshotRepository.shared.toggleFavorite(id: id)
                debugPrint("✅ 즐겨찾기 상태 토글 완료: \(id)")
            } catch {
                debugPrint("❌ 즐겨찾기 상태 토글 실패: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func addTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        tags.append(tag)
        scheduleSave()
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        scheduleSave()
    }
    
    // MARK: – Debounced Save
    private func scheduleSave() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            Task { await self?.saveChanges() }
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    // MARK: – Persistence & Sync
    func saveChanges() async {
        isSaving = true
        defer { isSaving = false }
        
        let item = ScreenshotItem(
            id: id,
            imageData: Data(), // imageData handled by PhotoLoader
            imageURL: imageURL, // ✅ 서버 URL 포함
            fileName: fileName,
            createDate: createDate,
            tags: tags,
            isFavorite: isFavorite
        )
        
        do {
            if AccountStorage.shared.isGuest ?? true {
                // 게스트 모드: 로컬 전용 저장
                try SwiftDataManager.shared.upsert(item: item)
                debugPrint("✅ 로컬 전용 저장 완료: \(fileName)")
            } else {
                // 로그인 모드: 서버 전용 저장 (로컬 저장 X)
                try await ScreenshotRepository.shared.saveToServerOnly(self)
                debugPrint("✅ 서버 전용 저장 완료: \(fileName)")
            }
            
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ 저장 실패: \(error.localizedDescription)")
        }
    }
    
    /// 로컬에만 저장 (게스트 모드 전용)
    func saveToLocal() async {
        guard AccountStorage.shared.isGuest ?? true else {
            debugPrint("⚠️ 로그인 모드에서는 로컬 저장을 사용할 수 없습니다.")
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        let item = ScreenshotItem(
            id: id,
            imageData: Data(),
            imageURL: imageURL, // ✅ 서버 URL 포함
            fileName: fileName,
            createDate: createDate,
            tags: tags,
            isFavorite: isFavorite
        )
        
        do {
            try SwiftDataManager.shared.upsert(item: item)
            debugPrint("✅ 로컬 저장 완료: \(fileName)")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ 로컬 저장 실패: \(error.localizedDescription)")
        }
    }
    
    /// 서버에만 저장 (로그인 모드 전용)
    func saveToServer() async {
        guard !(AccountStorage.shared.isGuest ?? true) else {
            debugPrint("⚠️ 게스트 모드에서는 서버 저장을 사용할 수 없습니다.")
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await ScreenshotRepository.shared.saveToServerOnly(self)
            debugPrint("✅ 서버 저장 완료: \(fileName)")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ 서버 저장 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: – Delete
    func delete() async throws {
        if AccountStorage.shared.isGuest ?? true {
            try SwiftDataManager.shared.delete(id: id)
        } else {
            _ = await ImageService.shared.deleteImage(id: id)
        }
    }
    
    // MARK: – DTO Mapping
    func toDTO() -> PhotoDTO {
        PhotoDTO(
            id: id,
            fileName: fileName,
            createDate: createDate,
            tags: tags,
            isFavorite: isFavorite,
            imageData: thumbnail?.jpegData(compressionQuality: 0.8)
        )
    }
}
